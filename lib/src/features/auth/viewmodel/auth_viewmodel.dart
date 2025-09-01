import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

/// 인증 화면의 상태를 나타내는 클래스
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final UserModel? user;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

/// 인증 화면의 비즈니스 로직을 처리하는 ViewModel
class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository) : super(AuthState());

  /// Google 로그인 처리
  Future<bool> signInWithGoogle() async {
    // 로딩 상태 시작
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Google 로그인 시도
      final user = await _authRepository.signInWithGoogle();
      
      if (user != null) {
        // 로그인 성공
        state = state.copyWith(
          isLoading: false,
          user: user,
          errorMessage: null,
        );
        return true;
      } else {
        // 사용자가 로그인 취소
        state = state.copyWith(
          isLoading: false,
          errorMessage: '로그인이 취소되었습니다.',
        );
        return false;
      }
    } catch (e) {
      // 로그인 실패
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Apple 로그인 처리
  Future<bool> signInWithApple() async {
    // 로딩 상태 시작
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Apple 로그인 시도
      final user = await _authRepository.signInWithApple();
      
      if (user != null) {
        // 로그인 성공
        state = state.copyWith(
          isLoading: false,
          user: user,
          errorMessage: null,
        );
        return true;
      } else {
        // 사용자가 로그인 취소
        state = state.copyWith(
          isLoading: false,
          errorMessage: '로그인이 취소되었습니다.',
        );
        return false;
      }
    } catch (e) {
      // 로그인 실패
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// AuthViewModel Provider
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthViewModel(authRepository);
});