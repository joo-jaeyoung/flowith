import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/room_model.dart';
import '../../core/constants.dart';
import 'auth_repository.dart';

/// 스터디 룸 관련 비즈니스 로직을 처리하는 Repository
/// Firestore와 연동하여 룸 생성, 참여, 타이머 관리 등을 담당
class RoomRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  RoomRepository({
    FirebaseFirestore? firestore,
    required AuthRepository authRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authRepository = authRepository;

  /// 룸 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _roomsCollection =>
      _firestore.collection(AppConstants.roomsCollection);

  /// 새로운 룸 생성
  Future<RoomModel> createRoom(String roomName) async {
    try {
      final firebaseUser = _authRepository.currentUser;
      if (firebaseUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 룸 이름 검증
      if (roomName.isEmpty || roomName.length > AppConstants.maxRoomNameLength) {
        throw Exception('룸 이름은 1~${AppConstants.maxRoomNameLength}자 이내로 입력해주세요.');
      }

      // 새 룸 문서 생성
      final roomDoc = _roomsCollection.doc();
      
      // 룸 데이터 생성
      final room = RoomModel(
        roomId: roomDoc.id,
        roomName: roomName,
        hostUid: firebaseUser.uid,
        participants: [
          Participant(
            uid: firebaseUser.uid,
            displayName: firebaseUser.displayName ?? 'User',
            photoUrl: firebaseUser.photoURL,
          ),
        ],
        timerState: AppConstants.roomStateIdle,
        setDurationSeconds: 0,
        startTime: null,
        endTime: null,
        createdAt: DateTime.now(),
      );

      // Firestore에 저장
      await roomDoc.set(room.toFirestore());
      
      return room;
    } catch (e) {
      debugPrint('Error creating room: $e');
      throw Exception('룸 생성에 실패했습니다: $e');
    }
  }

  /// 룸 참여
  Future<RoomModel> joinRoom(String roomId) async {
    try {
      final firebaseUser = _authRepository.currentUser;
      if (firebaseUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final roomDoc = _roomsCollection.doc(roomId);
      final roomSnapshot = await roomDoc.get();

      if (!roomSnapshot.exists) {
        throw Exception(AppConstants.errorRoomNotFound);
      }

      final room = RoomModel.fromFirestore(roomSnapshot);

      // 이미 참여 중인지 확인
      if (room.hasParticipant(firebaseUser.uid)) {
        return room; // 이미 참여 중이면 그대로 반환
      }

      // 최대 참여자 수 확인
      if (room.participants.length >= AppConstants.maxParticipants) {
        throw Exception(AppConstants.errorRoomFull);
      }

      // 참여자 추가
      final newParticipant = Participant(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? 'User',
        photoUrl: firebaseUser.photoURL,
      );

      await roomDoc.update({
        'participants': FieldValue.arrayUnion([newParticipant.toMap()]),
      });

      // 업데이트된 룸 정보 반환
      final updatedSnapshot = await roomDoc.get();
      return RoomModel.fromFirestore(updatedSnapshot);
    } catch (e) {
      debugPrint('Error joining room: $e');
      throw Exception('룸 참여에 실패했습니다: $e');
    }
  }

  /// 룸 나가기
  Future<void> leaveRoom(String roomId) async {
    try {
      final firebaseUser = _authRepository.currentUser;
      if (firebaseUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final roomDoc = _roomsCollection.doc(roomId);
      final roomSnapshot = await roomDoc.get();

      if (!roomSnapshot.exists) {
        return; // 룸이 이미 삭제된 경우
      }

      final room = RoomModel.fromFirestore(roomSnapshot);

      // 방장이 나가는 경우 룸 삭제
      if (room.isHost(firebaseUser.uid)) {
        await roomDoc.delete();
        return;
      }

      // 일반 참여자가 나가는 경우
      final participantToRemove = room.participants
          .firstWhere((p) => p.uid == firebaseUser.uid, 
              orElse: () => throw Exception('참여자를 찾을 수 없습니다.'));

      await roomDoc.update({
        'participants': FieldValue.arrayRemove([participantToRemove.toMap()]),
      });
    } catch (e) {
      debugPrint('Error leaving room: $e');
      throw Exception('룸 나가기에 실패했습니다: $e');
    }
  }

  /// 타이머 시작
  Future<void> startTimer(String roomId, int durationSeconds) async {
    try {
      final firebaseUser = _authRepository.currentUser;
      if (firebaseUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final roomDoc = _roomsCollection.doc(roomId);
      final roomSnapshot = await roomDoc.get();

      if (!roomSnapshot.exists) {
        throw Exception(AppConstants.errorRoomNotFound);
      }

      final room = RoomModel.fromFirestore(roomSnapshot);

      // 방장만 타이머를 시작할 수 있음
      if (!room.isHost(firebaseUser.uid)) {
        throw Exception('방장만 타이머를 시작할 수 있습니다.');
      }

      // 최소 참여자 수 확인
      if (room.participants.length < AppConstants.minParticipants) {
        throw Exception(AppConstants.errorMinParticipants);
      }

      // 타이머가 이미 실행 중인지 확인
      if (room.timerState == AppConstants.roomStateRunning) {
        throw Exception('타이머가 이미 실행 중입니다.');
      }

      final now = DateTime.now();
      final endTime = now.add(Duration(seconds: durationSeconds));

      // 타이머 정보 업데이트
      await roomDoc.update({
        'timerState': AppConstants.roomStateRunning,
        'setDurationSeconds': durationSeconds,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': Timestamp.fromDate(endTime),
      });
    } catch (e) {
      debugPrint('Error starting timer: $e');
      throw Exception('타이머 시작에 실패했습니다: $e');
    }
  }

  /// 타이머 종료 (완료 상태로 변경)
  Future<void> finishTimer(String roomId) async {
    try {
      final roomDoc = _roomsCollection.doc(roomId);
      
      await roomDoc.update({
        'timerState': AppConstants.roomStateFinished,
      });

      // 룸 정보 가져오기
      final roomSnapshot = await roomDoc.get();
      if (roomSnapshot.exists) {
        final room = RoomModel.fromFirestore(roomSnapshot);
        
        // 각 참여자의 completedDates 업데이트
        for (final participant in room.participants) {
          await _updateUserCompletedDate(participant.uid);
        }
        
        debugPrint('Timer finished for room: $roomId');
      }
    } catch (e) {
      debugPrint('Error finishing timer: $e');
      throw Exception('타이머 종료에 실패했습니다: $e');
    }
  }

  /// 사용자의 완료 날짜 업데이트
  Future<void> _updateUserCompletedDate(String uid) async {
    try {
      final userDoc = _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid);

      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);

      // 문서 존재 여부 확인
      final docSnapshot = await userDoc.get();
      
      if (docSnapshot.exists) {
        // 기존 문서가 있으면 업데이트
        await userDoc.update({
          'completedDates': FieldValue.arrayUnion([Timestamp.fromDate(dateOnly)]),
        });
        debugPrint('Updated completed date for user $uid');
      } else {
        // 문서가 없으면 생성 (혹시 모를 경우를 위해)
        debugPrint('User document not found for $uid, skipping completed date update');
      }
    } catch (e) {
      debugPrint('Error updating user completed date for $uid: $e');
    }
  }

  /// 타이머 리셋 (idle 상태로 변경)
  Future<void> resetTimer(String roomId) async {
    try {
      final firebaseUser = _authRepository.currentUser;
      if (firebaseUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final roomDoc = _roomsCollection.doc(roomId);
      final roomSnapshot = await roomDoc.get();

      if (!roomSnapshot.exists) {
        throw Exception(AppConstants.errorRoomNotFound);
      }

      final room = RoomModel.fromFirestore(roomSnapshot);

      // 방장만 타이머를 리셋할 수 있음
      if (!room.isHost(firebaseUser.uid)) {
        throw Exception('방장만 타이머를 리셋할 수 있습니다.');
      }

      await roomDoc.update({
        'timerState': AppConstants.roomStateIdle,
        'setDurationSeconds': 0,
        'startTime': null,
        'endTime': null,
      });
    } catch (e) {
      debugPrint('Error resetting timer: $e');
      throw Exception('타이머 리셋에 실패했습니다: $e');
    }
  }

  /// 특정 룸 정보 가져오기
  Future<RoomModel?> getRoom(String roomId) async {
    try {
      final roomDoc = await _roomsCollection.doc(roomId).get();
      
      if (roomDoc.exists) {
        return RoomModel.fromFirestore(roomDoc);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting room: $e');
      return null;
    }
  }

  /// 특정 룸 실시간 스트림
  Stream<RoomModel?> roomStream(String roomId) {
    return _roomsCollection
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return RoomModel.fromFirestore(snapshot);
          }
          return null;
        });
  }

  /// 사용자가 참여 중인 룸 목록 가져오기
  Stream<List<RoomModel>> getUserRooms(String uid) {
    return _roomsCollection
        .where('participants', arrayContainsAny: [
          {'uid': uid}
        ])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList();
        });
  }

  /// 룸 삭제
  Future<void> deleteRoom(String roomId) async {
    try {
      await _roomsCollection.doc(roomId).delete();
    } catch (e) {
      debugPrint('Error deleting room: $e');
      throw Exception('룸 삭제에 실패했습니다: $e');
    }
  }
}

/// RoomRepository Provider
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return RoomRepository(authRepository: authRepository);
});

/// 특정 룸 스트림 Provider
final roomStreamProvider = StreamProvider.family<RoomModel?, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).roomStream(roomId);
});