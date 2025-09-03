import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../data/models/user_model.dart';
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

  @override
  void initState() {
    super.initState();
    _focusedDay = ValueNotifier(DateTime.now());
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _focusedDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final currentUserAsync = ref.watch(currentUserModelProvider);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('나의 집중 기록'),
      ),
      body: authState.when(
        data: (firebaseUser) {
          if (firebaseUser == null) {
            return const Center(
              child: Text('로그인이 필요합니다.'),
            );
          }
          
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

              // 완료된 날짜들을 Set으로 변환 (빠른 조회를 위해)
              final completedDatesSet = user.completedDates.map((date) {
                return DateTime(date.year, date.month, date.day);
              }).toSet();

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 캘린더
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TableCalendar<dynamic>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay.value,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          calendarFormat: CalendarFormat.month, // 월간뷰로 고정
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          
                          // 날짜 선택 핸들러
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay.value = focusedDay;
                            });
                          },
                          
                          // 페이지 변경 핸들러
                          onPageChanged: (focusedDay) {
                            _focusedDay.value = focusedDay;
                          },
                          
                          // 헤더 스타일 (포맷 버튼 제거)
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false, // 포맷 버튼 완전 제거
                            titleCentered: true,
                            leftChevronIcon: Icon(Icons.chevron_left),
                            rightChevronIcon: Icon(Icons.chevron_right),
                          ),
                          
                          // 캘린더 스타일
                          calendarStyle: const CalendarStyle(
                            outsideDaysVisible: false,
                            markersMaxCount: 1,
                            markerDecoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          
                          // 자동 축소 방지 설정
                          sixWeekMonthsEnforced: false,
                          
                          // 이벤트 로더 - 완료된 날짜에 마커 표시
                          eventLoader: (day) {
                            final dayWithoutTime = DateTime(day.year, day.month, day.day);
                            return completedDatesSet.contains(dayWithoutTime) ? ['completed'] : [];
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 통계 정보 (캘린더 아래로 이동)
                      _buildStatsSection({
                        'totalDays': user.completedDates.length,
                        'thisWeekDays': _getThisWeekCount(user.completedDates),
                        'streakDays': _getStreakCount(user.completedDates),
                      }),
                      
                      const SizedBox(height: 24),
                      
                      // 선택된 날짜 정보 및 세션 목록
                      _buildSelectedDateInfo(completedDatesSet),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('오류가 발생했습니다: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('오류가 발생했습니다: $error'),
        ),
      ),
    );
  }

  /// 선택된 날짜 정보 위젯
  Widget _buildSelectedDateInfo(Set<DateTime> completedDatesSet) {
    final selectedDayWithoutTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final isCompleted = completedDatesSet.contains(selectedDayWithoutTime);
    
    // 집중한 날짜를 선택했을 때만 세션 목록 표시
    if (isCompleted) {
      return _buildSessionsList(_selectedDay);
    }
    
    // 집중하지 않은 날짜는 아무것도 표시하지 않음
    return const SizedBox.shrink();
  }

  /// 특정 날짜의 세션 목록 위젯
  Widget _buildSessionsList(DateTime date) {
    final sessionsAsync = ref.watch(userSessionsByDateProvider(date));
    
    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              '이 날의 집중 기록이 없습니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  '이 날의 집중 세션 (${sessions.length}개)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: sessions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _buildSessionCard(session);
                },
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '세션 정보를 불러오는데 실패했습니다: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  /// 개별 세션 카드 위젯
  Widget _buildSessionCard(SessionModel session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 세션 기본 정보
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  session.formattedDuration,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  session.roomName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                session.formattedStartTime,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 참여자 정보
          Row(
            children: [
              Icon(
                Icons.group,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${session.participants.length}명 참여',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  session.participants.map((p) => p.displayName).join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 통계 섹션 위젯
  Widget _buildStatsSection(Map<String, int> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '집중 통계',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '총 집중 일수',
                '${stats['totalDays']}일',
                Icons.calendar_today,
              ),
              _buildStatItem(
                '이번 주',
                '${stats['thisWeekDays']}일',
                Icons.date_range,
              ),
              _buildStatItem(
                '연속 기록',
                '${stats['streakDays']}일',
                Icons.local_fire_department,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 통계 로딩 위젯
  Widget _buildStatsLoadingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  /// 통계 에러 위젯
  Widget _buildStatsErrorSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        '통계 정보를 불러오는데 실패했습니다.',
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  /// 통계 아이템 위젯
  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: AppTheme.primaryGreen,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// 이번 주 집중 일수 계산
  int _getThisWeekCount(List<DateTime> completedDates) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return completedDates.where((date) {
      return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).length;
  }

  /// 연속 집중 일수 계산
  int _getStreakCount(List<DateTime> completedDates) {
    if (completedDates.isEmpty) return 0;

    // 날짜를 오름차순으로 정렬
    final sortedDates = [...completedDates]..sort();
    final today = DateTime.now();
    
    int streak = 0;
    DateTime currentDate = DateTime(today.year, today.month, today.day);
    
    // 오늘부터 거꾸로 체크하면서 연속된 날짜인지 확인
    for (int i = sortedDates.length - 1; i >= 0; i--) {
      final completedDate = DateTime(
        sortedDates[i].year,
        sortedDates[i].month,
        sortedDates[i].day,
      );
      
      if (completedDate.isAtSameMomentAs(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }
}