import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/timer_viewmodel.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../data/repositories/room_repository.dart';

/// Timer 화면 UI
/// 집중 시간 동안 타이머와 식물 성장을 표시
class TimerView extends ConsumerWidget {
  final String roomId;

  const TimerView({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerViewModelProvider(roomId));
    final timerViewModel = ref.read(timerViewModelProvider(roomId).notifier);
    final roomStream = ref.watch(roomStreamProvider(roomId));

    // 타이머가 종료되면 Result 화면으로 이동
    if (timerState.isFinishing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(
          '/result',
          arguments: roomId,
        );
      });
    }

    // 에러 메시지 표시
    if (timerState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(timerState.errorMessage!),
            action: SnackBarAction(
              label: '확인',
              onPressed: () {
                timerViewModel.clearError();
              },
            ),
          ),
        );
      });
    }

    return roomStream.when(
      data: (room) {
        if (room == null) {
          // 룸이 삭제된 경우
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/home');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundWhite,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.kLargePadding),
              child: Column(
                children: [
                  const SizedBox(height: AppConstants.kExtraLargePadding),
                  
                  // 타이머 표시
                  _buildTimer(context, timerState),
                  
                  const SizedBox(height: AppConstants.kExtraLargePadding),
                  
                  // 식물 성장 애니메이션
                  Expanded(
                    child: Center(
                      child: _buildPlantAnimation(timerState.plantStage),
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.kLargePadding),
                  
                  // 상태 메시지
                  Text(
                    '함께 집중하는 중...',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.kDefaultPadding),
                  
                  // 참여자 아바타
                  _buildParticipantAvatars(room),
                  
                  const SizedBox(height: AppConstants.kExtraLargePadding),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text('오류가 발생했습니다: $err'),
        ),
      ),
    );
  }

  /// 타이머 표시 위젯
  Widget _buildTimer(BuildContext context, TimerState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.kLargePadding,
        vertical: AppConstants.kDefaultPadding,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.kLargeRadius),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Text(
        state.formattedTime,
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGreen,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  /// 식물 성장 애니메이션
  Widget _buildPlantAnimation(int stage) {
    // 단계별 크기 조절
    final scale = 0.8 + (stage * 0.02);
    
    return AnimatedContainer(
      duration: AppConstants.normalAnimationDuration,
      width: 200 * scale,
      height: 200 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 원
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
          // 식물 아이콘 (단계별로 다른 아이콘 표시)
          AnimatedSwitcher(
            duration: AppConstants.normalAnimationDuration,
            child: Icon(
              _getPlantIcon(stage),
              key: ValueKey(stage),
              size: 80 * scale,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  /// 단계별 식물 아이콘 반환
  IconData _getPlantIcon(int stage) {
    // 단계별로 다른 아이콘 반환 (실제로는 이미지 사용)
    if (stage <= 2) {
      return Icons.grass; // 새싹
    } else if (stage <= 5) {
      return Icons.local_florist; // 작은 꽃
    } else if (stage <= 8) {
      return Icons.park; // 나무
    } else {
      return Icons.forest; // 큰 나무
    }
  }

  /// 참여자 아바타 표시
  Widget _buildParticipantAvatars(room) {
    List<Widget> avatars = room.participants.take(5).map<Widget>((participant) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.primaryGreen,
          child: Text(
            participant.displayName[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }).toList();
    
    // 5명 이상일 때 추가 표시
    if (room.participants.length > 5) {
      avatars.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.lightGreen,
            child: Text(
              '+${room.participants.length - 5}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: avatars,
    );
  }
}