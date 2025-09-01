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
  late TextEditingController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = TextEditingController();
  }

  @override
  void dispose() {
    _timerController.dispose();
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
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
                  child: Column(
                    children: [
                      // 참여자 섹션
                      _buildParticipantsSection(context, room),
                      
                      const SizedBox(height: AppConstants.kLargePadding),
                      
                      // 중앙 식물 이미지
                      Expanded(
                        child: Center(
                          child: _buildPlantImage(),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.kLargePadding),
                      
                      // 하단 컨트롤 섹션
                      _buildControlSection(
                        context,
                        room,
                        isHost,
                        studyRoomState,
                        studyRoomViewModel,
                      ),
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
      padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.kDefaultRadius),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '참여 중인 친구들 (${room.participants.length}명)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppConstants.kSmallPadding),
          Wrap(
            spacing: AppConstants.kSmallPadding,
            runSpacing: AppConstants.kSmallPadding,
            children: room.participants.map((participant) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    participant.displayName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                label: Text(participant.displayName),
                backgroundColor: AppTheme.lightGreen.withValues(alpha: 0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 식물 이미지 빌드
  Widget _buildPlantImage() {
    // 씨앗 단계 이미지 (placeholder)
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.eco,
        size: 80,
        color: AppTheme.primaryGreen,
      ),
    );
  }

  /// 하단 컨트롤 섹션 빌드
  Widget _buildControlSection(
    BuildContext context,
    RoomModel room,
    bool isHost,
    StudyRoomState state,
    StudyRoomViewModel viewModel,
  ) {
    return Column(
      children: [
        // 방장용 타이머 설정
        if (isHost) ...[
          Text(
            '집중 시간을 설정하세요 (분)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.kDefaultPadding),
          
          // 직접 입력 필드와 프리셋 버튼
          Row(
            children: [
              // 직접 입력 필드
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _timerController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '시간 입력',
                    suffix: const Text('분'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.kDefaultRadius),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value);
                    if (minutes != null && minutes > 0 && minutes <= 180) {
                      viewModel.setDuration(minutes * 60);
                    } else if (value.isEmpty) {
                      viewModel.setDuration(0);
                    }
                  },
                ),
              ),
              
              const SizedBox(width: AppConstants.kDefaultPadding),
              
              // 프리셋 버튼들
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPresetButton(
                      '10분',
                      AppConstants.timerPreset10Min,
                      state.selectedDuration == AppConstants.timerPreset10Min,
                      () {
                        viewModel.setDuration(AppConstants.timerPreset10Min);
                        _timerController.text = '10';
                      },
                    ),
                    _buildPresetButton(
                      '25분',
                      AppConstants.timerPreset25Min,
                      state.selectedDuration == AppConstants.timerPreset25Min,
                      () {
                        viewModel.setDuration(AppConstants.timerPreset25Min);
                        _timerController.text = '25';
                      },
                    ),
                    _buildPresetButton(
                      '50분',
                      AppConstants.timerPreset50Min,
                      state.selectedDuration == AppConstants.timerPreset50Min,
                      () {
                        viewModel.setDuration(AppConstants.timerPreset50Min);
                        _timerController.text = '50';
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.kSmallPadding),
          
          // 선택된 시간 표시
          if (state.selectedDuration > 0) 
            Text(
              '선택된 시간: ${state.selectedDuration ~/ 60}분',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          
          const SizedBox(height: AppConstants.kLargePadding),
        ],
        
        // 시작/초대 버튼
        Row(
          children: [
            // 친구 초대 버튼
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => viewModel.inviteFriends(),
                icon: const Icon(Icons.share),
                label: const Text('친구 초대하기'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            // 방장용 시작 버튼
            if (isHost) ...[
              const SizedBox(width: AppConstants.kDefaultPadding),
              Expanded(
                child: ElevatedButton(
                  onPressed: (room.participants.length >= AppConstants.minParticipants && 
                            state.selectedDuration > 0 &&
                            !state.isLoading)
                      ? () async {
                          print('Starting timer: participants=${room.participants.length}, duration=${state.selectedDuration}');
                          final success = await viewModel.startTimer();
                          if (success && context.mounted) {
                            Navigator.of(context).pushReplacementNamed(
                              '/timer',
                              arguments: widget.roomId,
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '시작하기',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ],
        ),
        
        // 시작 조건 안내
        if (isHost) ...[
          const SizedBox(height: AppConstants.kSmallPadding),
          if (room.participants.length < AppConstants.minParticipants)
            Text(
              '최소 ${AppConstants.minParticipants}명이 참여해야 시작할 수 있습니다.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            )
          else if (state.selectedDuration <= 0)
            Text(
              '집중 시간을 설정해주세요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
        ],
      ],
    );
  }

  /// 타이머 프리셋 버튼 빌드
  Widget _buildPresetButton(
    String label,
    int duration,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return Flexible(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : AppTheme.primaryGreen,
          side: BorderSide(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: const Size(0, 36),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
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
}