import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

// Core
import 'src/core/theme.dart';
import 'src/core/constants.dart';

// Views
import 'src/features/auth/view/auth_view.dart';
import 'src/features/home/view/home_view.dart';
import 'src/features/room/view/study_room_view.dart';
import 'src/features/timer/view/timer_view.dart';
import 'src/features/result/view/result_view.dart';
import 'src/features/calendar/view/calendar_view.dart';

// Repositories
import 'src/data/repositories/auth_repository.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화 (필수)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Firebase 초기화 실패 시 앱 실행 중단
    throw Exception('Firebase initialization failed. Please check your Firebase configuration.');
  }
  
  // 한국어 날짜 포맷 초기화
  await initializeDateFormatting('ko_KR', null);
  
  // 앱 실행
  runApp(
    const ProviderScope(
      child: FlowithApp(),
    ),
  );
}

/// Flowith 앱의 루트 위젯
class FlowithApp extends ConsumerWidget {
  const FlowithApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        data: (user) => user != null ? const HomeView() : const AuthView(),
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        error: (_, __) => const AuthView(),
      ),
      routes: {
        '/home': (_) => const HomeView(),
        '/auth': (_) => const AuthView(),
        '/calendar': (_) => const CalendarView(),
      },
      onGenerateRoute: _generateRoute,
    );
  }
  
  /// 공통 라우트 생성 함수
  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/auth':
        return MaterialPageRoute(
          builder: (_) => const AuthView(),
        );
        
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeView());
        
      case '/room':
        final roomId = settings.arguments as String?;
        if (roomId == null) {
          return MaterialPageRoute(builder: (_) => const HomeView());
        }
        return MaterialPageRoute(
          builder: (_) => StudyRoomView(roomId: roomId),
        );
        
      case '/timer':
        final roomId = settings.arguments as String?;
        if (roomId == null) {
          return MaterialPageRoute(builder: (_) => const HomeView());
        }
        return MaterialPageRoute(
          builder: (_) => TimerView(roomId: roomId),
        );
        
      case '/result':
        final roomId = settings.arguments as String?;
        if (roomId == null) {
          return MaterialPageRoute(builder: (_) => const HomeView());
        }
        return MaterialPageRoute(
          builder: (_) => ResultView(roomId: roomId),
        );
        
      case '/calendar':
        return MaterialPageRoute(builder: (_) => const CalendarView());
        
      default:
        return MaterialPageRoute(
          builder: (_) => const _NotFoundScreen(),
        );
    }
  }
}


/// 404 Not Found 스크린
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '페이지를 찾을 수 없습니다',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}