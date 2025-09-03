import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/study_room_viewmodel.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/room_model.dart';

/// Study Room 화면 UI
/// 타이머 시작 전 대기 화면
class StudyRoomView extends ConsumerStatefulWidget {
  final String roomId;

  const StudyRoomView({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<StudyRoomView> createState() => _StudyRoomViewState();
}

class _StudyRoomViewState extends ConsumerState<StudyRoomView> {
  late TextEditingController _minutesController;
  late TextEditingController _secondsController;
  
  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController();
    _secondsController = TextEditingController();
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomStream = ref.watch(roomStreamProvider(widget.roomId));
    final studyRoomState = ref.watch(studyRoomViewModelProvider(widget.roomId));
    final studyRoomViewModel = ref.read(studyRoomViewModelProvider(widget.roomId).notifier);
    final authState = ref.watch(authStateProvider);

    // 에러 메시지 표시
    if (studyRoomState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(studyRoomState.errorMessage!),
            action: SnackBarAction(
              label: '확인',
              onPressed: () {
                studyRoomViewModel.clearError();
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

        // 타이머가 실행 중이면 Timer View로 이동
        if (room.timerState == AppConstants.roomStateRunning) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(
              '/timer',
              arguments: widget.roomId,
            );
          });
        }

        return authState.when(
          data: (firebaseUser) {
            final isHost = firebaseUser != null && room.isHost(firebaseUser.uid);
            print('StudyRoomView: participants=${room.participants.length}, minParticipants=${AppConstants.minParticipants}, isHost=$isHost');
            print('CurrentUser: ${firebaseUser?.uid}, RoomHostId: ${room.hostUid}');
            
            return Scaffold(
              backgroundColor: AppTheme.backgroundWhite,
              appBar: AppBar(
                title: Text(room.roomName),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _showExitDialog(context, studyRoomViewModel),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 참여자 섹션
                      _buildParticipantsSection(context, room),
                      
                      const SizedBox(height: AppConstants.kDefaultPadding),
                      
                      // 컨트롤 섹션
                      _buildControlSection(
                        context,
                        room,
                        isHost,
                        studyRoomState,
                        studyRoomViewModel,
                      ),
                      
                      const SizedBox(height: AppConstants.kDefaultPadding),
                      
                      // 집중 팁 카드
                      if (!isHost || studyRoomState.selectedDuration == 0)
                        _buildFocusTipCard(context),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Scaffold(
            body: Center(
              child: Text('오류가 발생했습니다: $err'),
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

  /// 참여자 섹션 빌드
  Widget _buildParticipantsSection(BuildContext context, RoomModel room) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '참여자 ${room.participants.length}명',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (room.participants.length >= AppConstants.minParticipants)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '준비완료',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 참여자 아바타들을 가로로 배치
          Row(
            children: [
              ...room.participants.take(5).map((participant) => 
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(
                      participant.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              if (room.participants.length > 5)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '+${room.participants.length - 5}',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 컨트롤 섹션 빌드
  Widget _buildControlSection(
    BuildContext context,
    RoomModel room,
    bool isHost,
    StudyRoomState state,
    StudyRoomViewModel viewModel,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 방장용 타이머 설정
          if (isHost) ...[
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '집중 시간 설정',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 프리셋 버튼들 (더 작고 컴팩트하게)
            Row(
              children: [
                Expanded(
                  child: _buildTimerButton('10분', 10 * 60, state.selectedDuration, viewModel),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimerButton('25분', 25 * 60, state.selectedDuration, viewModel),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTimerButton('50분', 50 * 60, state.selectedDuration, viewModel),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 커스텀 시간 입력 (분:초 형식)
            Text(
              '또는 직접 설정하기',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: '분',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(':', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _secondsController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '00',
                      suffixText: '초',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _setCustomTime(viewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('설정'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 타이머 시작 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: room.participants.length >= AppConstants.minParticipants && 
                           state.selectedDuration > 0 && 
                           !state.isLoading
                    ? () => _startTimer(context, viewModel, state.selectedDuration)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            state.selectedDuration > 0 
                                ? '집중 시작 (${_formatDuration(state.selectedDuration)})'
                                : '시간을 선택하세요',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ],
          
          // 친구 초대 섹션
          if (!isHost || state.selectedDuration == 0) ...[
            if (isHost && state.selectedDuration == 0) 
              const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '더 많은 친구들과 함께하세요',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => viewModel.inviteFriends(),
                icon: const Icon(Icons.share),
                label: const Text('친구 초대하기'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          
          // 최소 참여자 안내
          if (room.participants.length < AppConstants.minParticipants) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '최소 ${AppConstants.minParticipants}명이 필요합니다',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 타이머 버튼 빌드 헬퍼
  Widget _buildTimerButton(String label, int duration, int selectedDuration, StudyRoomViewModel viewModel) {
    final isSelected = selectedDuration == duration;
    return ElevatedButton(
      onPressed: () => viewModel.setDuration(duration),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryGreen : Colors.grey.shade100,
        foregroundColor: isSelected ? Colors.white : AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  /// 커스텀 시간 설정
  void _setCustomTime(StudyRoomViewModel viewModel) {
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    
    if (minutes > 0 || seconds > 0) {
      final totalSeconds = (minutes * 60) + seconds;
      if (totalSeconds <= 3600) { // 최대 1시간 제한
        viewModel.setDuration(totalSeconds);
        _minutesController.clear();
        _secondsController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('최대 1시간까지만 설정할 수 있습니다.'),
          ),
        );
      }
    }
  }

  /// 시간을 포맷된 문자열로 변환
  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (seconds == 0) {
      return '${minutes}분';
    } else if (minutes == 0) {
      return '${seconds}초';
    } else {
      return '${minutes}분 ${seconds}초';
    }
  }

  /// 타이머 시작 헬퍼 메서드
  Future<void> _startTimer(BuildContext context, StudyRoomViewModel viewModel, int duration) async {
    print('Starting timer: duration=$duration');
    final success = await viewModel.startTimer();
    if (success && context.mounted) {
      Navigator.of(context).pushReplacementNamed(
        '/timer',
        arguments: widget.roomId,
      );
    }
  }

  /// 나가기 확인 다이얼로그
  void _showExitDialog(BuildContext context, StudyRoomViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('룸 나가기'),
          content: const Text('정말로 룸을 나가시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await viewModel.leaveRoom();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('나가기'),
            ),
          ],
        );
      },
    );
  }

  /// 집중 팁 카드 빌드
  Widget _buildFocusTipCard(BuildContext context) {
    final tips = [
      '💡 핸드폰을 멀리 두고 집중해보세요',
      '🎧 집중에 도움되는 음악을 들어보세요', 
      '💧 충분한 수분 섭취도 중요해요',
      '🌱 작은 목표부터 달성해나가세요',
      '⏰ 25분 집중 + 5분 휴식 패턴을 시도해보세요',
    ];
    final randomTip = tips[(DateTime.now().millisecondsSinceEpoch / 1000 % tips.length).floor()];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.lightGreen.withValues(alpha: 0.1),
            AppTheme.primaryGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '집중 팁',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            randomTip,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}