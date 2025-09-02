import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../../core/constants.dart';
import 'auth_repository.dart';

/// 집중 세션 관련 데이터를 관리하는 Repository
class SessionRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  SessionRepository({
    FirebaseFirestore? firestore,
    required AuthRepository authRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authRepository = authRepository;

  /// 세션 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _sessionsCollection =>
      _firestore.collection('sessions');

  /// 새로운 세션 저장
  Future<void> saveSession({
    required String roomId,
    required String roomName,
    required String hostUid,
    required List<SessionParticipant> participants,
    required int durationSeconds,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final sessionDoc = _sessionsCollection.doc();
      
      final session = SessionModel(
        sessionId: sessionDoc.id,
        roomId: roomId,
        roomName: roomName,
        hostUid: hostUid,
        participants: participants,
        durationSeconds: durationSeconds,
        startTime: startTime,
        endTime: endTime,
        createdAt: DateTime.now(),
      );

      await sessionDoc.set(session.toFirestore());
      debugPrint('Session saved: ${session.sessionId}');
    } catch (e) {
      debugPrint('Error saving session: $e');
      throw Exception('세션 저장에 실패했습니다: $e');
    }
  }

  /// 특정 사용자의 모든 세션 가져오기 (날짜 역순 정렬)
  Stream<List<SessionModel>> getUserSessions(String uid) {
    return _sessionsCollection
        .where('participants', arrayContainsAny: [
          {'uid': uid}
        ])
        .orderBy('endTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SessionModel.fromFirestore(doc))
              .toList();
        });
  }

  /// 특정 날짜의 사용자 세션 가져오기
  Future<List<SessionModel>> getUserSessionsByDate(String uid, DateTime date) async {
    try {
      // 해당 날짜의 시작과 끝 시간 계산
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // 먼저 날짜 범위로 세션들을 가져온 다음, 메모리에서 uid로 필터링
      final querySnapshot = await _sessionsCollection
          .where('endTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('endTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('endTime', descending: false)
          .get();

      // 참여자 목록에서 현재 사용자가 포함된 세션만 필터링
      return querySnapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .where((session) => session.participants.any((p) => p.uid == uid))
          .toList();
    } catch (e) {
      debugPrint('Error getting user sessions by date: $e');
      return [];
    }
  }

  /// 특정 사용자의 총 집중 일수 계산 (세션이 있는 날의 수)
  Future<int> getTotalFocusDays(String uid) async {
    try {
      final querySnapshot = await _sessionsCollection.get();

      // 참여자 목록에서 현재 사용자가 포함된 세션만 필터링하고 날짜별로 그룹화
      final focusedDates = <String>{};
      for (final doc in querySnapshot.docs) {
        final session = SessionModel.fromFirestore(doc);
        if (session.participants.any((p) => p.uid == uid)) {
          final dateStr = '${session.endTime.year}-${session.endTime.month}-${session.endTime.day}';
          focusedDates.add(dateStr);
        }
      }

      return focusedDates.length;
    } catch (e) {
      debugPrint('Error getting total focus days: $e');
      return 0;
    }
  }

  /// 특정 사용자의 이번 주 집중 일수 계산
  Future<int> getThisWeekFocusDays(String uid) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final endOfWeek = startOfWeekDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final querySnapshot = await _sessionsCollection
          .where('endTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekDate))
          .where('endTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .get();

      // 이번 주에 세션이 완료된 날짜들을 Set으로 수집 (중복 제거)
      final focusedDates = <String>{};
      for (final doc in querySnapshot.docs) {
        final session = SessionModel.fromFirestore(doc);
        if (session.participants.any((p) => p.uid == uid)) {
          final dateStr = '${session.endTime.year}-${session.endTime.month}-${session.endTime.day}';
          focusedDates.add(dateStr);
        }
      }

      return focusedDates.length;
    } catch (e) {
      debugPrint('Error getting this week focus days: $e');
      return 0;
    }
  }

  /// 특정 사용자의 연속 집중 일수 계산
  Future<int> getStreakDays(String uid) async {
    try {
      final querySnapshot = await _sessionsCollection
          .orderBy('endTime', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) return 0;

      // 세션이 완료된 날짜들을 Set으로 수집 (중복 제거)
      final focusedDates = <DateTime>{};
      for (final doc in querySnapshot.docs) {
        final session = SessionModel.fromFirestore(doc);
        if (session.participants.any((p) => p.uid == uid)) {
          final date = DateTime(session.endTime.year, session.endTime.month, session.endTime.day);
          focusedDates.add(date);
        }
      }

      // 날짜들을 내림차순으로 정렬
      final sortedDates = focusedDates.toList()..sort((a, b) => b.compareTo(a));
      
      int streak = 0;
      final today = DateTime.now();
      DateTime currentDate = DateTime(today.year, today.month, today.day);

      // 오늘부터 거꾸로 체크하면서 연속된 날짜인지 확인
      for (final focusDate in sortedDates) {
        if (focusDate.isAtSameMomentAs(currentDate)) {
          streak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      debugPrint('Error getting streak days: $e');
      return 0;
    }
  }

  /// 특정 사용자의 집중 완료 날짜들 가져오기 (캘린더 마커용)
  Future<List<DateTime>> getUserCompletedDates(String uid) async {
    try {
      final querySnapshot = await _sessionsCollection.get();

      // 세션이 완료된 날짜들을 Set으로 수집 (중복 제거)
      final completedDates = <DateTime>{};
      for (final doc in querySnapshot.docs) {
        final session = SessionModel.fromFirestore(doc);
        if (session.participants.any((p) => p.uid == uid)) {
          final date = DateTime(session.endTime.year, session.endTime.month, session.endTime.day);
          completedDates.add(date);
        }
      }

      return completedDates.toList()..sort();
    } catch (e) {
      debugPrint('Error getting user completed dates: $e');
      return [];
    }
  }
}

/// SessionRepository Provider
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SessionRepository(authRepository: authRepository);
});

/// 특정 날짜의 사용자 세션 목록 Provider
final userSessionsByDateProvider = FutureProvider.family<List<SessionModel>, DateTime>((ref, date) async {
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  
  final currentUser = authRepository.currentUser;
  if (currentUser == null) return [];
  
  return sessionRepository.getUserSessionsByDate(currentUser.uid, date);
});

/// 사용자 통계 Provider
final userStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  
  final currentUser = authRepository.currentUser;
  if (currentUser == null) {
    return {
      'totalDays': 0,
      'thisWeekDays': 0,
      'streakDays': 0,
    };
  }
  
  final totalDays = await sessionRepository.getTotalFocusDays(currentUser.uid);
  final thisWeekDays = await sessionRepository.getThisWeekFocusDays(currentUser.uid);
  final streakDays = await sessionRepository.getStreakDays(currentUser.uid);
  
  return {
    'totalDays': totalDays,
    'thisWeekDays': thisWeekDays,
    'streakDays': streakDays,
  };
});

/// 사용자 완료 날짜 Provider (캘린더용)
final userCompletedDatesProvider = FutureProvider<List<DateTime>>((ref) async {
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  
  final currentUser = authRepository.currentUser;
  if (currentUser == null) return [];
  
  return sessionRepository.getUserCompletedDates(currentUser.uid);
});