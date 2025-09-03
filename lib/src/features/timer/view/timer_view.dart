import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/timer_viewmodel.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../data/repositories/room_repository.dart';

/// Timer 화면 UI
/// 집중 시간 동안 타이머와 식물 성장을 표시
class TimerView extends ConsumerStatefulWidget {
  final String roomId;

  const TimerView({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends ConsumerState<TimerView> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // 기본값, 실제 타이머 시간으로 업데이트됨
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startProgressAnimation(int durationSeconds) {
    _progressController.duration = Duration(seconds: durationSeconds);
    _progressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerViewModelProvider(widget.roomId));
    final timerViewModel = ref.read(timerViewModelProvider(widget.roomId).notifier);
    final roomStream = ref.watch(roomStreamProvider(widget.roomId));

    // 타이머가 종료되면 Result 화면으로 이동
    if (timerState.isFinishing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(
          '/result',
          arguments: widget.roomId,
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

        // 타이머가 시작되었을 때 애니메이션 시작
        if (room.timerState == AppConstants.roomStateRunning && 
            !_progressController.isAnimating && 
            _progressController.value == 0.0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startProgressAnimation(room.setDurationSeconds);
          });
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundWhite,
          body: SafeArea(
            child: Column(
              children: [
                // 상단 헤더
                _buildHeader(context, room, timerState),
                
                // 메인 컨텐츠
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.kLargePadding),
                    child: Column(
                      children: [
                        // 타이머와 진행률 (메인)
                        _buildTimerSection(context, timerState, room),
                        
                        const SizedBox(height: AppConstants.kDefaultPadding),
                        
                        // 집중 상태 (간소화)
                        _buildFocusStatusSection(timerState),
                        
                        const SizedBox(height: AppConstants.kLargePadding),
                        
                        // 참여자 정보 (메인)
                        Expanded(
                          child: _buildParticipantSection(room),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

  /// 상단 헤더
  Widget _buildHeader(BuildContext context, room, TimerState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kLargePadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.1),
            AppTheme.lightGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.kLargeRadius),
          bottomRight: Radius.circular(AppConstants.kLargeRadius),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.timer,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.roomName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${room.participants.length}명이 함께 집중 중',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 타이머 섹션 (개선된 진행률)
  Widget _buildTimerSection(BuildContext context, TimerState state, room) {
    final progress = room.getProgress();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kLargePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kLargeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 원형 진행률과 타이머
          Stack(
            alignment: Alignment.center,
            children: [
              // 원형 진행률 배경
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: 1.0, // 배경 원
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[200]!),
                ),
              ),
              // 원형 진행률 실제 값 (연속 애니메이션)
              SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    final animatedProgress = _progressAnimation.value;
                    return CircularProgressIndicator(
                      value: animatedProgress,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressiveColor(animatedProgress),
                      ),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
              // 중앙의 타이머 텍스트
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.formattedTime,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 진행률에 따라 점진적으로 진해지는 색상 반환
  Color _getProgressiveColor(double progress) {
    // 진행률에 따라 알파값을 0.3에서 1.0으로 점진적으로 증가
    final alpha = 0.3 + (progress * 0.7); // 0.3 ~ 1.0
    return AppTheme.primaryGreen.withValues(alpha: alpha);
  }

  /// 집중 상태 섹션 (간소화)
  Widget _buildFocusStatusSection(TimerState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.kLargePadding,
        vertical: AppConstants.kDefaultPadding,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConstants.kDefaultRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 24,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(width: 12),
          Text(
            '깊은 집중 중',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }


  /// 참여자 섹션 (메인 컨텐츠)
  Widget _buildParticipantSection(room) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kLargePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.kLargeRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 참여자 수 강조
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.kDefaultPadding,
              vertical: AppConstants.kSmallPadding,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.group,
                  color: AppTheme.primaryGreen,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${room.participants.length}명이 함께 집중 중',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppConstants.kLargePadding),
          
          // 참여자 아바타들 (더 큰 크기)
          Flexible(
            child: _buildParticipantAvatars(room),
          ),
        ],
      ),
    );
  }


  /// 참여자 아바타 표시 (더 크고 시각적으로 강조)
  Widget _buildParticipantAvatars(room) {
    List<Widget> avatars = room.participants.take(6).map<Widget>((participant) {
      return Container(
        margin: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 더 큰 아바타
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primaryGreen,
                child: Text(
                  participant.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 이름 표시
            Container(
              constraints: const BoxConstraints(maxWidth: 70),
              child: Text(
                participant.displayName.length > 8 
                  ? '${participant.displayName.substring(0, 8)}...'
                  : participant.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
    
    // 6명 이상일 때 추가 표시
    if (room.participants.length > 6) {
      avatars.add(
        Container(
          margin: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightGreen.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.lightGreen,
                  child: Text(
                    '+${room.participants.length - 6}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '더보기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: avatars,
    );
  }

}