import 'package:cloud_firestore/cloud_firestore.dart';

/// 사용자 정보를 담는 데이터 모델
/// Firestore의 users 컬렉션과 매핑됨
class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final List<DateTime> completedDates; // 세션을 완료한 날짜들

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.completedDates,
  });

  /// Firestore 문서로부터 UserModel 객체 생성
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // completedDates를 Timestamp 리스트에서 DateTime 리스트로 변환
    final completedDatesData = data['completedDates'] as List<dynamic>? ?? [];
    final completedDates = completedDatesData
        .map((timestamp) => (timestamp as Timestamp).toDate())
        .toList();

    return UserModel(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedDates: completedDates,
    );
  }

  /// JSON 형태로 UserModel 객체 생성
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // completedDates 처리
    final completedDatesData = json['completedDates'] as List<dynamic>? ?? [];
    final completedDates = completedDatesData
        .map((dateStr) => DateTime.parse(dateStr as String))
        .toList();

    return UserModel(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      completedDates: completedDates,
    );
  }

  /// UserModel을 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedDates': completedDates.map((date) => Timestamp.fromDate(date)).toList(),
    };
  }

  /// UserModel을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'completedDates': completedDates.map((date) => date.toIso8601String()).toList(),
    };
  }

  /// 완료된 날짜 추가 (중복 방지)
  UserModel addCompletedDate(DateTime date) {
    // 날짜만 비교 (시간 제외)
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // 이미 존재하는 날짜인지 확인
    final alreadyExists = completedDates.any((existingDate) =>
        existingDate.year == dateOnly.year &&
        existingDate.month == dateOnly.month &&
        existingDate.day == dateOnly.day);

    if (alreadyExists) {
      return this;
    }

    return copyWith(
      completedDates: [...completedDates, dateOnly],
    );
  }

  /// copyWith 메서드 - 일부 필드만 변경한 새 객체 생성
  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    List<DateTime>? completedDates,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, displayName: $displayName, email: $email, completedDates: ${completedDates.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.uid == uid &&
        other.displayName == displayName &&
        other.email == email &&
        other.photoUrl == photoUrl &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        displayName.hashCode ^
        email.hashCode ^
        (photoUrl?.hashCode ?? 0) ^
        createdAt.hashCode;
  }
}