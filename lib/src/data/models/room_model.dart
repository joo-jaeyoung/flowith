import 'package:cloud_firestore/cloud_firestore.dart';

/// 스터디 룸 정보를 담는 데이터 모델
/// Firestore의 rooms 컬렉션과 매핑됨
class RoomModel {
  final String roomId;
  final String roomName;
  final String hostUid; // 방장의 UID
  final List<Participant> participants; // 참여자 목록
  final String timerState; // idle, running, finished
  final int setDurationSeconds; // 설정된 타이머 시간 (초)
  final DateTime? startTime; // 타이머 시작 시간
  final DateTime? endTime; // 타이머 종료 예정 시간
  final DateTime createdAt;

  RoomModel({
    required this.roomId,
    required this.roomName,
    required this.hostUid,
    required this.participants,
    required this.timerState,
    required this.setDurationSeconds,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  /// Firestore 문서로부터 RoomModel 객체 생성
  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // participants 리스트 변환
    final participantsData = data['participants'] as List<dynamic>? ?? [];
    final participants = participantsData
        .map((p) => Participant.fromMap(p as Map<String, dynamic>))
        .toList();

    return RoomModel(
      roomId: doc.id,
      roomName: data['roomName'] ?? '',
      hostUid: data['hostUid'] ?? '',
      participants: participants,
      timerState: data['timerState'] ?? 'idle',
      setDurationSeconds: data['setDurationSeconds'] ?? 0,
      startTime: data['startTime'] != null 
          ? (data['startTime'] as Timestamp).toDate() 
          : null,
      endTime: data['endTime'] != null 
          ? (data['endTime'] as Timestamp).toDate() 
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// JSON 형태로 RoomModel 객체 생성
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // participants 리스트 변환
    final participantsData = json['participants'] as List<dynamic>? ?? [];
    final participants = participantsData
        .map((p) => Participant.fromMap(p as Map<String, dynamic>))
        .toList();

    return RoomModel(
      roomId: json['roomId'] ?? '',
      roomName: json['roomName'] ?? '',
      hostUid: json['hostUid'] ?? '',
      participants: participants,
      timerState: json['timerState'] ?? 'idle',
      setDurationSeconds: json['setDurationSeconds'] ?? 0,
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime']) 
          : null,
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// RoomModel을 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'hostUid': hostUid,
      'participants': participants.map((p) => p.toMap()).toList(),
      'timerState': timerState,
      'setDurationSeconds': setDurationSeconds,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// RoomModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'hostUid': hostUid,
      'participants': participants.map((p) => p.toMap()).toList(),
      'timerState': timerState,
      'setDurationSeconds': setDurationSeconds,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 현재 사용자가 방장인지 확인
  bool isHost(String uid) {
    return hostUid == uid;
  }

  /// 특정 사용자가 참여자인지 확인
  bool hasParticipant(String uid) {
    return participants.any((p) => p.uid == uid);
  }

  /// 남은 시간 계산 (초 단위)
  int getRemainingSeconds() {
    if (timerState != 'running' || endTime == null) {
      return 0;
    }
    
    final now = DateTime.now();
    final difference = endTime!.difference(now);
    
    return difference.isNegative ? 0 : difference.inSeconds;
  }

  /// 진행률 계산 (0.0 ~ 1.0)
  double getProgress() {
    if (timerState != 'running' || startTime == null || endTime == null) {
      return 0.0;
    }
    
    final now = DateTime.now();
    final totalDuration = endTime!.difference(startTime!);
    final elapsedDuration = now.difference(startTime!);
    
    if (totalDuration.inSeconds == 0) {
      return 0.0;
    }
    
    final progress = elapsedDuration.inSeconds / totalDuration.inSeconds;
    return progress.clamp(0.0, 1.0);
  }

  /// 현재 식물 성장 단계 계산 (0~10)
  int getPlantStage() {
    final progress = getProgress();
    return (progress * 10).floor();
  }

  /// copyWith 메서드 - 일부 필드만 변경한 새 객체 생성
  RoomModel copyWith({
    String? roomId,
    String? roomName,
    String? hostUid,
    List<Participant>? participants,
    String? timerState,
    int? setDurationSeconds,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      hostUid: hostUid ?? this.hostUid,
      participants: participants ?? this.participants,
      timerState: timerState ?? this.timerState,
      setDurationSeconds: setDurationSeconds ?? this.setDurationSeconds,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'RoomModel(roomId: $roomId, roomName: $roomName, timerState: $timerState, participants: ${participants.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RoomModel &&
        other.roomId == roomId &&
        other.roomName == roomName &&
        other.hostUid == hostUid &&
        other.timerState == timerState;
  }

  @override
  int get hashCode {
    return roomId.hashCode ^
        roomName.hashCode ^
        hostUid.hashCode ^
        timerState.hashCode;
  }
}

/// 참여자 정보를 담는 서브 모델
class Participant {
  final String uid;
  final String displayName;
  final String? photoUrl;

  Participant({
    required this.uid,
    required this.displayName,
    this.photoUrl,
  });

  /// Map으로부터 Participant 객체 생성
  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }

  /// Participant를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  @override
  String toString() {
    return 'Participant(uid: $uid, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Participant &&
        other.uid == uid &&
        other.displayName == displayName;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ displayName.hashCode;
  }
}