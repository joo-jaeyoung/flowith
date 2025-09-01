import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../models/room_model.dart';
import '../../core/constants.dart';
import 'auth_repository.dart';

/// 세션 기록 관련 비즈니스 로직을 처리하는 Repository
class SessionRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  SessionRepository({
    FirebaseFirestore? firestore,
    required AuthRepository authRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authRepository = authRepository;

  /// 세션 기록 저장
  Future<void> saveSession(RoomModel room) async {
    try {
      if (room.startTime == null || room.endTime == null) {
        debugPrint('Session save failed: start or end time is null');
        return;
      }

      final sessionId = _firestore.collection('sessions').doc().id;
      
      // SessionModel 생성
      final session = SessionModel(
        sessionId: sessionId,
        roomId: room.roomId,
        roomName: room.roomName,
        durationMinutes: room.setDurationSeconds ~/ 60,
        startTime: room.startTime!,
        endTime: room.endTime!,
        participants: room.participants.map((p) => SessionParticipant(
          uid: p.uid,
          displayName: p.displayName,
          photoUrl: p.photoUrl,
        )).toList(),
        createdAt: DateTime.now(),
      );

      // 각 참여자의 개별 세션 기록 저장
      for (final participant in room.participants) {
        await _saveUserSession(participant.uid, session);
      }

      debugPrint('Session saved successfully: $sessionId');
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  /// 사용자별 세션 기록 저장
  Future<void> _saveUserSession(String uid, SessionModel session) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('sessions')
          .doc(session.sessionId)
          .set(session.toFirestore());
    } catch (e) {
      debugPrint('Error saving user session for $uid: $e');
    }
  }

  /// 사용자의 세션 기록 목록 가져오기 (페이지네이션)
  Future<List<SessionModel>> getUserSessions({
    String? userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      final uid = userId ?? _authRepository.currentUser?.uid;
      if (uid == null) return [];

      Query query = _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('sessions')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user sessions: $e');
      return [];
    }
  }

  /// 특정 날짜의 세션 목록 가져오기
  Future<List<SessionModel>> getSessionsByDate(DateTime date) async {
    try {
      final uid = _authRepository.currentUser?.uid;
      if (uid == null) return [];

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('sessions')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('startTime', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting sessions by date: $e');
      return [];
    }
  }

  /// 사용자의 전체 세션 통계 가져오기
  Future<Map<String, dynamic>> getUserStats({String? userId}) async {
    try {
      final uid = userId ?? _authRepository.currentUser?.uid;
      if (uid == null) return {};

      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('sessions')
          .get();

      final sessions = snapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();

      // 통계 계산
      final totalSessions = sessions.length;
      final totalMinutes = sessions.fold(0, (sum, session) => sum + session.durationMinutes);
      final uniqueDays = sessions.map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day)).toSet().length;
      
      // 이번 주 세션 수
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      final thisWeekSessions = sessions.where((session) {
        final sessionDate = session.startTime;
        return sessionDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            sessionDate.isBefore(weekEnd.add(const Duration(days: 1)));
      }).length;

      return {
        'totalSessions': totalSessions,
        'totalMinutes': totalMinutes,
        'totalHours': (totalMinutes / 60).round(),
        'uniqueDays': uniqueDays,
        'thisWeekSessions': thisWeekSessions,
        'averageMinutesPerSession': totalSessions > 0 ? (totalMinutes / totalSessions).round() : 0,
      };
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return {};
    }
  }

  /// 세션 기록 스트림 (실시간 업데이트)
  Stream<List<SessionModel>> getUserSessionsStream({String? userId, int limit = 10}) {
    final uid = userId ?? _authRepository.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection('sessions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SessionModel.fromFirestore(doc))
            .toList());
  }
}

/// SessionRepository Provider
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SessionRepository(authRepository: authRepository);
});

/// 사용자 세션 목록 StreamProvider
final userSessionsStreamProvider = StreamProvider.family<List<SessionModel>, int>((ref, limit) {
  return ref.watch(sessionRepositoryProvider).getUserSessionsStream(limit: limit);
});

/// 사용자 통계 FutureProvider
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(sessionRepositoryProvider).getUserStats();
});