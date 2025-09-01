import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/home_viewmodel.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../data/repositories/auth_repository.dart';

/// Home 화면 UI
/// 룸 생성 및 참여 기능 제공
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final TextEditingController _roomNameController = TextEditingController();

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);
    final currentUser = ref.watch(currentUserModelProvider);

    // 에러 메시지가 있으면 SnackBar 표시
    if (homeState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(homeState.errorMessage!),
            action: SnackBarAction(
              label: '확인',
              onPressed: () {
                homeViewModel.clearError();
              },
            ),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          // 캘린더 버튼
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              // Navigate to Calendar View
              Navigator.pushNamed(context, '/calendar');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
          child: Column(
            children: [
              // 환영 메시지
              currentUser.when(
                data: (user) => _buildWelcomeCard(context, user),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              
              const SizedBox(height: AppConstants.kDefaultPadding),
              
              // 통계 카드들
              currentUser.when(
                data: (user) => _buildStatsSection(context, user),
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
              
              const SizedBox(height: AppConstants.kDefaultPadding),
              
              // 빠른 액션 섹션
              _buildQuickActions(context, homeState, homeViewModel),
              
              const SizedBox(height: AppConstants.kDefaultPadding),
              
              // 룸 참여 섹션
              _buildJoinRoomSection(context),
              
              const SizedBox(height: AppConstants.kDefaultPadding),
              
              // 팁 섹션
              _buildTipSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 환영 메시지 카드
  Widget _buildWelcomeCard(BuildContext context, user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.1),
            AppTheme.lightGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.kDefaultRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.kDefaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, ${user?.displayName ?? 'User'}님!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '오늘도 집중하는 시간을 가져보세요 🌱',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 통계 섹션
  Widget _buildStatsSection(BuildContext context, user) {
    final completedDates = user?.completedDates ?? <DateTime>[];
    final thisWeekCount = _getThisWeekCount(completedDates);
    final totalCount = completedDates.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            '이번 주',
            thisWeekCount.toString(),
            '일',
            Icons.date_range,
            AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: AppConstants.kDefaultPadding),
        Expanded(
          child: _buildStatCard(
            context,
            '전체 기록',
            totalCount.toString(),
            '일',
            Icons.emoji_events,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  /// 통계 카드
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.kDefaultRadius),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 빠른 액션 섹션
  Widget _buildQuickActions(
    BuildContext context,
    homeState,
    homeViewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 시작',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.kSmallPadding),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                '룸 만들기',
                '새로운 스터디 룸을 만들어보세요',
                Icons.add_circle_outline,
                AppTheme.primaryGreen,
                () => _showCreateRoomDialog(context, homeViewModel),
                isLoading: homeState.isCreatingRoom,
              ),
            ),
            const SizedBox(width: AppConstants.kDefaultPadding),
            Expanded(
              child: _buildActionCard(
                context,
                '룸 참여',
                '친구의 룸에 참여해보세요',
                Icons.group_add,
                Colors.blue,
                () => _showJoinRoomDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 액션 카드
  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.kDefaultRadius),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                icon,
                size: 32,
                color: color,
              ),
            const SizedBox(height: AppConstants.kSmallPadding),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 룸 참여 섹션
  Widget _buildJoinRoomSection(BuildContext context) {
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
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                '룸 참여 방법',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.kSmallPadding),
          Text(
            '친구가 공유한 룸 코드나 링크를 통해 스터디 룸에 참여할 수 있어요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 팁 섹션
  Widget _buildTipSection(BuildContext context) {
    final tips = [
      '🌱 집중할 때는 핸드폰을 멀리 두세요',
      '⏰ 25분 집중 + 5분 휴식이 효과적이에요',
      '👥 친구들과 함께하면 더 오래 집중할 수 있어요',
      '🎯 명확한 목표를 세우고 시작하세요',
    ];
    
    final currentTip = tips[DateTime.now().day % tips.length];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.1),
            Colors.amber.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.kDefaultRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: AppConstants.kDefaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘의 팁',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentTip,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 이번 주 완료 횟수 계산
  int _getThisWeekCount(List<DateTime> completedDates) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return completedDates.where((date) {
      return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          date.isBefore(weekEnd.add(const Duration(days: 1)));
    }).length;
  }

  /// 룸 참여 다이얼로그
  void _showJoinRoomDialog(BuildContext context) {
    final roomCodeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('룸 참여하기'),
          content: TextField(
            controller: roomCodeController,
            decoration: const InputDecoration(
              hintText: '룸 코드를 입력하세요',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                roomCodeController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final roomCode = roomCodeController.text.trim();
                if (roomCode.isNotEmpty) {
                  // TODO: 룸 참여 로직 구현
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('룸 참여 기능은 준비 중입니다.'),
                    ),
                  );
                }
                roomCodeController.clear();
              },
              child: const Text('참여'),
            ),
          ],
        );
      },
    );
  }

  /// 룸 생성 다이얼로그 표시
  void _showCreateRoomDialog(BuildContext context, HomeViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('스터디 룸 만들기'),
          content: TextField(
            controller: _roomNameController,
            decoration: InputDecoration(
              hintText: AppConstants.placeholderRoomName,
              counterText: '${_roomNameController.text.length}/${AppConstants.maxRoomNameLength}',
            ),
            maxLength: AppConstants.maxRoomNameLength,
            autofocus: true,
            onChanged: (value) {
              // 텍스트 길이 카운터 업데이트를 위해 setState 호출
              setState(() {});
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                _roomNameController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final roomName = _roomNameController.text;
                Navigator.of(context).pop();
                
                print('Creating room with name: $roomName');
                
                // 룸 생성
                final room = await viewModel.createRoom(roomName);
                
                print('Room creation result: ${room?.roomId}');
                
                if (room != null && context.mounted) {
                  print('Navigating to room: ${room.roomId}');
                  // 룸 생성 성공 - Study Room으로 이동
                  Navigator.pushNamed(
                    context,
                    '/room',
                    arguments: room.roomId,
                  );
                } else {
                  print('Room creation failed or context not mounted');
                }
                
                _roomNameController.clear();
              },
              child: const Text('만들기'),
            ),
          ],
        );
      },
    );
  }
}