import 'package:cloud_firestore/cloud_firestore.dart';

/// 집중 세션의 상세 정보를 저장하는 모델
class SessionModel {
  final String sessionId;
  final String roomId;
  final String roomName;
  final String hostUid;
  final List<SessionParticipant> participants;
  final int durationSeconds; // 설정된 집중 시간 (초)
  final DateTime startTime; // 세션 시작 시간
  final DateTime endTime; // 세션 완료 시간
  final DateTime createdAt;

  SessionModel({
    required this.sessionId,
    required this.roomId,
    required this.roomName,
    required this.hostUid,
    required this.participants,
    required this.durationSeconds,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  /// Firestore 문서로부터 SessionModel 객체 생성
  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // participants 리스트 변환
    final participantsData = data['participants'] as List<dynamic>? ?? [];
    final participants = participantsData
        .map((p) => SessionParticipant.fromMap(p as Map<String, dynamic>))
        .toList();

    return SessionModel(
      sessionId: doc.id,
      roomId: data['roomId'] ?? '',
      roomName: data['roomName'] ?? '',
      hostUid: data['hostUid'] ?? '',
      participants: participants,
      durationSeconds: data['durationSeconds'] ?? 0,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// JSON 형태로 SessionModel 객체 생성
  factory SessionModel.fromJson(Map<String, dynamic> json) {
    final participantsData = json['participants'] as List<dynamic>? ?? [];
    final participants = participantsData
        .map((p) => SessionParticipant.fromMap(p as Map<String, dynamic>))
        .toList();

    return SessionModel(
      sessionId: json['sessionId'] ?? '',
      roomId: json['roomId'] ?? '',
      roomName: json['roomName'] ?? '',
      hostUid: json['hostUid'] ?? '',
      participants: participants,
      durationSeconds: json['durationSeconds'] ?? 0,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// SessionModel을 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'hostUid': hostUid,
      'participants': participants.map((p) => p.toMap()).toList(),
      'durationSeconds': durationSeconds,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// SessionModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'roomId': roomId,
      'roomName': roomName,
      'hostUid': hostUid,
      'participants': participants.map((p) => p.toMap()).toList(),
      'durationSeconds': durationSeconds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 집중 시간을 분 단위로 반환
  int get durationMinutes => (durationSeconds / 60).round();

  /// 집중 시간을 포맷팅된 문자열로 반환 (예: "25분", "1시간 30분")
  String get formattedDuration {
    final minutes = durationMinutes;
    if (minutes < 60) {
      return '${minutes}분';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}시간';
      } else {
        return '${hours}시간 ${remainingMinutes}분';
      }
    }
  }

  /// 시작 시간을 포맷팅된 문자열로 반환 (예: "오후 2:30")
  String get formattedStartTime {
    final hour = startTime.hour;
    final minute = startTime.minute;
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$period ${displayHour}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'SessionModel(sessionId: $sessionId, roomName: $roomName, participants: ${participants.length}, duration: ${formattedDuration})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionModel && other.sessionId == sessionId;
  }

  @override
  int get hashCode => sessionId.hashCode;
}

/// 세션 참여자 정보를 담는 모델
class SessionParticipant {
  final String uid;
  final String displayName;
  final String? photoUrl;

  SessionParticipant({
    required this.uid,
    required this.displayName,
    this.photoUrl,
  });

  /// Map으로부터 SessionParticipant 객체 생성
  factory SessionParticipant.fromMap(Map<String, dynamic> map) {
    return SessionParticipant(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }

  /// SessionParticipant를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  @override
  String toString() {
    return 'SessionParticipant(uid: $uid, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionParticipant && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}