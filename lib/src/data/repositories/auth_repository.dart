import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../core/constants.dart';

/// 인증 관련 비즈니스 로직을 처리하는 Repository
/// Firebase Authentication과 연동하여 Google/Apple 로그인 제공
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// 현재 로그인된 사용자 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 현재 로그인된 Firebase User
  User? get currentUser => _auth.currentUser;

  /// 현재 사용자의 UserModel 가져오기
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user model: $e');
      return null;
    }
  }

  /// Google 로그인
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Google 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // 사용자가 로그인 취소
        return null;
      }

      // Google 인증 정보 획득
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Firebase 인증 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      // Firestore에 사용자 정보 저장/업데이트
      if (userCredential.user != null) {
        return await _createOrUpdateUser(userCredential.user!);
      }

      return null;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      throw Exception(AppConstants.errorAuthFailed);
    }
  }

  /// Apple 로그인
  Future<UserModel?> signInWithApple() async {
    try {
      // Apple 로그인 자격 증명 요청
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Firebase OAuth 자격 증명 생성
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Firebase에 로그인
      final UserCredential userCredential = 
          await _auth.signInWithCredential(oauthCredential);

      // Firestore에 사용자 정보 저장/업데이트
      if (userCredential.user != null) {
        // Apple 로그인의 경우 이름이 처음 로그인 시에만 제공됨
        String displayName = userCredential.user!.displayName ?? '';
        if (displayName.isEmpty && appleCredential.givenName != null) {
          displayName = '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim();
          
          // Firebase Auth 프로필 업데이트
          await userCredential.user!.updateDisplayName(displayName);
        }

        return await _createOrUpdateUser(userCredential.user!);
      }

      return null;
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
      throw Exception(AppConstants.errorAuthFailed);
    }
  }

  /// Firestore에 사용자 정보 생성 또는 업데이트
  Future<UserModel> _createOrUpdateUser(User firebaseUser) async {
    final userDoc = _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid);

    final docSnapshot = await userDoc.get();

    if (docSnapshot.exists) {
      // 기존 사용자 - 정보 업데이트
      await userDoc.update({
        'displayName': firebaseUser.displayName ?? '',
        'email': firebaseUser.email ?? '',
        'photoUrl': firebaseUser.photoURL,
      });

      return UserModel.fromFirestore(await userDoc.get());
    } else {
      // 신규 사용자 - 새로 생성
      final newUser = UserModel(
        uid: firebaseUser.uid,
        displayName: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        completedDates: [],
      );

      await userDoc.set(newUser.toFirestore());
      return newUser;
    }
  }

  /// 완료된 날짜 추가
  Future<void> addCompletedDate(DateTime date) async {
    final user = currentUser;
    if (user == null) return;

    final userDoc = _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid);

    // 날짜만 비교 (시간 제외)
    final dateOnly = DateTime(date.year, date.month, date.day);

    try {
      await userDoc.update({
        'completedDates': FieldValue.arrayUnion([Timestamp.fromDate(dateOnly)]),
      });
      debugPrint('Added completed date: $dateOnly for user ${user.uid}');
    } catch (e) {
      debugPrint('Error adding completed date: $e');
    }
  }

  /// 테스트용: 오늘 날짜를 완료 기록에 추가
  Future<void> addTodayAsCompleted() async {
    final user = currentUser;
    if (user == null) {
      debugPrint('addTodayAsCompleted: No current user');
      return;
    }
    
    debugPrint('addTodayAsCompleted: Starting for user ${user.uid}');
    
    try {
      // 먼저 사용자 문서가 존재하는지 확인
      final userDoc = _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid);
      
      final docSnapshot = await userDoc.get();
      debugPrint('addTodayAsCompleted: User document exists: ${docSnapshot.exists}');
      
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        debugPrint('addTodayAsCompleted: Current completedDates: ${userData['completedDates']}');
        
        await addCompletedDate(DateTime.now());
        debugPrint('addTodayAsCompleted: Completed successfully');
      } else {
        // 문서가 없으면 새로 생성
        debugPrint('addTodayAsCompleted: Creating new user document');
        final newUser = UserModel(
          uid: user.uid,
          displayName: user.displayName ?? 'User',
          email: user.email ?? '',
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          completedDates: [DateTime.now()], // 오늘 날짜를 포함하여 생성
        );
        
        await userDoc.set(newUser.toFirestore());
        debugPrint('addTodayAsCompleted: New user document created with today\'s date');
      }
    } catch (e) {
      debugPrint('addTodayAsCompleted: Error - $e');
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    try {
      // Google 로그아웃
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      // Firebase 로그아웃
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('로그아웃에 실패했습니다.');
    }
  }

  /// 계정 삭제
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) return;

      // Firestore에서 사용자 데이터 삭제
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .delete();

      // Firebase Auth에서 계정 삭제
      await user.delete();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      throw Exception('계정 삭제에 실패했습니다.');
    }
  }
}

/// AuthRepository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// 현재 사용자 스트림 Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// 현재 사용자 모델 Provider (실시간 업데이트)
final currentUserModelProvider = StreamProvider<UserModel?>((ref) async* {
  final authRepository = ref.watch(authRepositoryProvider);
  
  // Firebase Auth 상태 변화를 구독
  await for (final user in authRepository.authStateChanges) {
    if (user == null) {
      yield null;
    } else {
      // 사용자가 있으면 Firestore에서 실시간으로 사용자 문서 구독
      await for (final snapshot in FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .snapshots()) {
        if (snapshot.exists) {
          yield UserModel.fromFirestore(snapshot);
        } else {
          yield null;
        }
      }
    }
  }
});

/// 구버전 호환용 (FutureProvider)
final currentUserModelFutureProvider = FutureProvider<UserModel?>((ref) async {
  // authState가 변경되면 자동으로 재계산됨
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) async {
      if (user == null) {
        return null;
      }
      return await ref.read(authRepositoryProvider).getCurrentUserModel();
    },
    loading: () => null,
    error: (_, __) => null,
  );
});