import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../data/models/session_model.dart';

/// Calendar 화면 UI
/// 사용자의 집중 기록을 캘린더 형태로 표시
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  late final ValueNotifier<DateTime> _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<SessionModel> _selectedDaySessions = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = ValueNotifier(DateTime.now());
    _selectedDay = DateTime.now();
    _loadSelectedDaySessions();
  }

  @override
  void dispose() {
    _focusedDay.dispose();
    super.dispose();
  }

  /// 선택된 날짜의 세션들을 로드
  Future<void> _loadSelectedDaySessions() async {
    final sessionRepo = ref.read(sessionRepositoryProvider);
    final sessions = await sessionRepo.getSessionsByDate(_selectedDay);
    if (mounted) {
      setState(() {
        _selectedDaySessions = sessions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserModelProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('나의 집중 기록'),
        actions: [
          // 테스트용 버튼 - 오늘 날짜 기록 추가
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: () async {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('기록을 추가하고 있습니다...')),
                );
              }
              
              try {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.addTodayAsCompleted();
                
                // 잠깐 기다린 후 Provider를 새로고침
                await Future.delayed(const Duration(milliseconds: 500));
                ref.invalidate(currentUserModelProvider);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ 테스트 기록이 추가되었습니다!')),
                  );
                }
              } catch (e) {
                print('Error adding test record: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ 오류 발생: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: authState.when(
        data: (firebaseUser) {
          if (firebaseUser == null) {
            return const Center(
              child: Text('로그인이 필요합니다.'),
            );
          }
          
          // Firebase User가 있으면 currentUserModel을 가져옴
          return currentUserAsync.when(
            data: (user) {
              if (user == null) {
                // 임시로 빈 사용자 데이터로 UI 표시
                user = UserModel(
                  uid: firebaseUser.uid,
                  displayName: firebaseUser.displayName ?? 'User',
                  email: firebaseUser.email ?? '',
                  photoUrl: firebaseUser.photoURL,
                  createdAt: DateTime.now(),
                  completedDates: [], // 빈 완료 날짜 리스트
                );
              }
              
              // 디버깅용 로그
              print('CalendarView - User completed dates: ${user.completedDates.length} dates');
              for (final date in user.completedDates) {
                print('  - ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
              }

          // 완료된 날짜들을 Set으로 변환 (빠른 조회를 위해)
          final completedDatesSet = user.completedDates.map((date) {
            return DateTime(date.year, date.month, date.day);
          }).toSet();

          return Column(
            children: [
              // 캘린더
              Container(
                color: AppTheme.surfaceWhite,
                child: TableCalendar<dynamic>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay.value,
                  calendarFormat: _calendarFormat,
                  locale: 'ko_KR',
                  
                  // 스타일 설정
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: const TextStyle(color: AppTheme.textPrimary),
                    holidayTextStyle: const TextStyle(color: AppTheme.textPrimary),
                    
                    // 선택된 날짜 스타일
                    selectedDecoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                    
                    // 오늘 날짜 스타일
                    todayDecoration: BoxDecoration(
                      color: AppTheme.lightGreen.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    
                    // 마커 스타일
                    markerDecoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 1,
                    markersAlignment: Alignment.bottomCenter,
                  ),
                  
                  // 헤더 스타일
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: AppTheme.textPrimary,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: AppTheme.textPrimary,
                    ),
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  
                  // 날짜 선택 핸들러
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay.value = focusedDay;
                    });
                    _loadSelectedDaySessions();
                  },
                  
                  // 포맷 변경 핸들러
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  
                  // 페이지 변경 핸들러
                  onPageChanged: (focusedDay) {
                    _focusedDay.value = focusedDay;
                  },
                  
                  // 이벤트 로더 (완료된 날짜에 마커 표시)
                  eventLoader: (day) {
                    final dateOnly = DateTime(day.year, day.month, day.day);
                    if (completedDatesSet.contains(dateOnly)) {
                      return ['completed']; // 마커 표시용 더미 이벤트
                    }
                    return [];
                  },
                  
                  // 커스텀 빌더
                  calendarBuilders: CalendarBuilders(
                    // 마커 빌더 (식물 아이콘)
                    markerBuilder: (context, date, events) {
                      if (events.isNotEmpty) {
                        return Positioned(
                          bottom: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.eco,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ),
              
              // 세션 세부 정보 섹션
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 선택된 날짜 헤더
                      Row(
                        children: [
                          Text(
                            DateFormat('yyyy년 MM월 dd일').format(_selectedDay),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedDaySessions.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedDaySessions.length}개 세션',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: AppConstants.kDefaultPadding),
                      
                      // 세션 목록
                      Expanded(
                        child: _selectedDaySessions.isEmpty
                            ? _buildEmptyState(context)
                            : ListView.separated(
                                itemCount: _selectedDaySessions.length,
                                separatorBuilder: (context, index) => 
                                    const SizedBox(height: AppConstants.kSmallPadding),
                                itemBuilder: (context, index) {
                                  final session = _selectedDaySessions[index];
                                  return _buildSessionCard(context, session);
                                },
                              ),
                      ),
                      
                      const SizedBox(height: AppConstants.kDefaultPadding),
                      
                      // 일간 요약 통계
                      if (_selectedDaySessions.isNotEmpty)
                        _buildDaySummary(context, _selectedDaySessions),
                    ],
                  ),
                ),
              ),
            ],
          );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) => Center(
              child: Text('사용자 정보를 가져올 수 없습니다: $err'),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Text('인증 오류가 발생했습니다: $err'),
        ),
      ),
    );
  }

  /// 세션 카드 빌드
  Widget _buildSessionCard(BuildContext context, SessionModel session) {
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
          // 헤더 (룸명과 시간)
          Row(
            children: [
              Expanded(
                child: Text(
                  session.roomName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${session.durationMinutes}분',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.kSmallPadding),
          
          // 시간 정보
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                session.timeRangeString,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.kSmallPadding),
          
          // 참여자 정보
          Row(
            children: [
              Icon(
                session.isSoloSession ? Icons.person : Icons.group,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  session.isSoloSession 
                      ? '혼자 집중'
                      : '${session.participantNamesString} (${session.participants.length}명)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppConstants.kDefaultPadding),
          Text(
            '이날은 집중 기록이 없어요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.kSmallPadding),
          Text(
            '집중 세션을 완료하면 여기에 기록됩니다',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 일간 요약 위젯
  Widget _buildDaySummary(BuildContext context, List<SessionModel> sessions) {
    final totalMinutes = sessions.fold(0, (total, session) => total + session.durationMinutes);
    final totalSessions = sessions.length;
    final uniqueParticipants = sessions
        .expand((s) => s.participants)
        .map((p) => p.uid)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(AppConstants.kDefaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.kDefaultRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이날의 요약',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.kSmallPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                '총 집중 시간',
                '${totalMinutes}분',
                Icons.timer,
              ),
              _buildSummaryItem(
                context,
                '세션 횟수',
                '${totalSessions}회',
                Icons.refresh,
              ),
              _buildSummaryItem(
                context,
                '함께한 친구',
                '${uniqueParticipants}명',
                Icons.people,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 요약 아이템 위젯
  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryGreen,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}