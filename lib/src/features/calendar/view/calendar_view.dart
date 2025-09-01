import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';

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
    final currentUserAsync = ref.watch(currentUserModelProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('나의 집중 기록'),
        actions: [
          // 테스트 버튼 (개발용)
          TextButton(
            onPressed: () async {
              try {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.addTodayAsCompleted();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('테스트 기록이 추가되었습니다!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('오류가 발생했습니다: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('테스트'),
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
                          calendarFormat: _calendarFormat,
                          
                          // 날짜 선택 핸들러
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay.value = focusedDay;
                            });
                          },
                          
                          // 포맷 변경 핸들러
                          onFormatChanged: (format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          },
                          
                          // 헤더 스타일
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
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
                          
                          // 이벤트 로더 - 완료된 날짜에 마커 표시
                          eventLoader: (day) {
                            final dayWithoutTime = DateTime(day.year, day.month, day.day);
                            return completedDatesSet.contains(dayWithoutTime) ? ['completed'] : [];
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 선택된 날짜 정보
                      _buildSelectedDateInfo(completedDatesSet),
                      
                      const SizedBox(height: 16),
                      
                      // 통계 정보
                      Container(
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
                                  '${user.completedDates.length}일',
                                  Icons.calendar_today,
                                ),
                                _buildStatItem(
                                  '이번 주',
                                  '${_getThisWeekCount(user.completedDates)}일',
                                  Icons.date_range,
                                ),
                                _buildStatItem(
                                  '연속 기록',
                                  '${_getStreakCount(user.completedDates)}일',
                                  Icons.local_fire_department,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
    final isToday = isSameDay(_selectedDay, DateTime.now());
    
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
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedDay.year}년 ${_selectedDay.month}월 ${_selectedDay.day}일',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '오늘',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.cancel,
                color: isCompleted ? AppTheme.primaryGreen : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCompleted ? '집중 완료' : '집중하지 않음',
                style: TextStyle(
                  fontSize: 14,
                  color: isCompleted ? AppTheme.primaryGreen : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (isCompleted) ...[
            const SizedBox(height: 8),
            Text(
              '이 날에 집중 세션을 완료했습니다! 🌱',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
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