import 'package:cloud_firestore/cloud_firestore.dart';

/// 집중 세션 기록을 담는 데이터 모델
class SessionModel {
  final String sessionId;
  final String roomId;
  final String roomName;
  final int durationMinutes; // 집중한 시간 (분)
  final DateTime startTime; // 시작 시간
  final DateTime endTime; // 종료 시간
  final List<SessionParticipant> participants; // 함께 참여한 사람들
  final DateTime createdAt; // 기록 생성 시간

  SessionModel({
    required this.sessionId,
    required this.roomId,
    required this.roomName,
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
    required this.participants,
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
      durationMinutes: data['durationMinutes'] ?? 0,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      participants: participants,
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
      durationMinutes: json['durationMinutes'] ?? 0,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      participants: participants,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// SessionModel을 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'durationMinutes': durationMinutes,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'participants': participants.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// SessionModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'roomId': roomId,
      'roomName': roomName,
      'durationMinutes': durationMinutes,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'participants': participants.map((p) => p.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 시간 범위를 포맷팅된 문자열로 반환 (예: "14:30 - 15:00")
  String get timeRangeString {
    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  /// 참여자 이름들을 문자열로 반환 (예: "철수, 영희, 민수")
  String get participantNamesString {
    return participants.map((p) => p.displayName).join(', ');
  }

  /// 혼자 진행한 세션인지 확인
  bool get isSoloSession {
    return participants.length == 1;
  }

  @override
  String toString() {
    return 'SessionModel(sessionId: $sessionId, roomName: $roomName, duration: ${durationMinutes}분, participants: ${participants.length}명)';
  }
}

/// 세션 참여자 정보를 담는 서브 모델
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
}