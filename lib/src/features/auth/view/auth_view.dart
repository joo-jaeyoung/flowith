import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import '../viewmodel/auth_viewmodel.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';

/// 인증 화면 UI
/// Google과 Apple 로그인 옵션을 제공
class AuthView extends ConsumerWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);

    // 에러 메시지가 있으면 SnackBar 표시
    if (authState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage!),
            action: SnackBarAction(
              label: '확인',
              onPressed: () {
                authViewModel.clearError();
              },
            ),
          ),
        );
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.kLargePadding,
          ),
          child: Column(
            children: [
              // 상단 여백
              const Expanded(flex: 2, child: SizedBox()),
              
              // 로고 이미지
              _buildLogo(),
              
              const SizedBox(height: AppConstants.kDefaultPadding),
              
              // 앱 이름
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppConstants.kSmallPadding),
              
              // 캐치프레이즈
              Text(
                AppConstants.appTagline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              
              // 중간 여백
              const Expanded(flex: 1, child: SizedBox()),
              
              // 로그인 버튼들
              if (authState.isLoading)
                const CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                )
              else
                Column(
                  children: [
                    // Google 로그인 버튼
                    _buildGoogleSignInButton(context, authViewModel),
                    
                    const SizedBox(height: AppConstants.kDefaultPadding),
                    
                    // Apple 로그인 버튼 (iOS에서만 표시)
                    if (Platform.isIOS)
                      _buildAppleSignInButton(context, authViewModel),
                  ],
                ),
              
              // 하단 여백
              const Expanded(flex: 2, child: SizedBox()),
              
              // 하단 안내 문구
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppConstants.kLargePadding,
                ),
                child: Text(
                  '로그인하면 서비스 이용약관에 동의하는 것으로 간주됩니다.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 로고 위젯 빌드
  Widget _buildLogo() {
    // 실제 로고 이미지가 없으므로 플레이스홀더 사용
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.eco,
        size: 60,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  /// Google 로그인 버튼 빌드
  Widget _buildGoogleSignInButton(
    BuildContext context,
    AuthViewModel viewModel,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () async {
          final success = await viewModel.signInWithGoogle();
          if (success && context.mounted) {
            // 로그인 성공 시 홈 화면으로 이동
            // Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: AppTheme.dividerColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.kDefaultRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google 아이콘 (플레이스홀더)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Google로 계속하기',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Apple 로그인 버튼 빌드
  Widget _buildAppleSignInButton(
    BuildContext context,
    AuthViewModel viewModel,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          final success = await viewModel.signInWithApple();
          if (success && context.mounted) {
            // 로그인 성공 시 홈 화면으로 이동
            // Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.kDefaultRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Apple 아이콘
            const Icon(
              Icons.apple,
              size: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            const Text(
              'Apple로 계속하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}