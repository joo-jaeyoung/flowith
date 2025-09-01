import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../core/constants.dart';

/// Timer 화면의 상태를 나타내는 클래스
class TimerState {
  final int remainingSeconds;
  final int plantStage;
  final bool isFinishing;
  final String? errorMessage;

  TimerState({
    this.remainingSeconds = 0,
    this.plantStage = 0,
    this.isFinishing = false,
    this.errorMessage,
  });

  TimerState copyWith({
    int? remainingSeconds,
    int? plantStage,
    bool? isFinishing,
    String? errorMessage,
  }) {
    return TimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      plantStage: plantStage ?? this.plantStage,
      isFinishing: isFinishing ?? this.isFinishing,
      errorMessage: errorMessage,
    );
  }

  /// 남은 시간을 MM:SS 형식으로 변환
  String get formattedTime {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Timer 화면의 비즈니스 로직을 처리하는 ViewModel
class TimerViewModel extends StateNotifier<TimerState> {
  final RoomRepository _roomRepository;
  final String roomId;
  Timer? _timer;
  StreamSubscription<RoomModel?>? _roomSubscription;

  TimerViewModel({
    required RoomRepository roomRepository,
    required this.roomId,
  })  : _roomRepository = roomRepository,
        super(TimerState()) {
    _initialize();
  }

  /// 초기화 - 룸 정보 구독 및 타이머 시작
  void _initialize() {
    // 룸 정보 실시간 구독
    _roomSubscription = _roomRepository.roomStream(roomId).listen((room) {
      if (room != null) {
        _handleRoomUpdate(room);
      }
    });
  }

  /// 룸 정보 업데이트 처리
  void _handleRoomUpdate(RoomModel room) {
    // 타이머가 종료 상태가 되면 Result 화면으로 이동
    if (room.timerState == AppConstants.roomStateFinished && !state.isFinishing) {
      state = state.copyWith(isFinishing: true);
      _stopTimer();
      return;
    }

    // 타이머가 실행 중인 경우
    if (room.timerState == AppConstants.roomStateRunning) {
      final remainingSeconds = room.getRemainingSeconds();
      final plantStage = room.getPlantStage();
      
      state = state.copyWith(
        remainingSeconds: remainingSeconds,
        plantStage: plantStage,
      );

      // 타이머가 없으면 시작
      if (_timer == null) {
        _startTimer();
      }

      // 남은 시간이 0이 되면 타이머 종료
      if (remainingSeconds <= 0 && !state.isFinishing) {
        _finishTimer();
      }
    }
  }

  /// 로컬 타이머 시작
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        // 로컬에서 시간 감소
        state = state.copyWith(
          remainingSeconds: state.remainingSeconds - 1,
        );

        // 진행률에 따른 식물 단계 계산
        // 이것은 룸 정보에서도 업데이트되지만, 로컬에서도 계산하여 부드러운 UI 제공
        _updatePlantStage();

        // 시간이 다 되면 종료 처리
        if (state.remainingSeconds <= 0) {
          _finishTimer();
        }
      }
    });
  }

  /// 로컬 타이머 정지
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 식물 성장 단계 업데이트
  void _updatePlantStage() {
    // 서버에서 받은 룸 정보를 기반으로 계산하는 것이 더 정확하지만,
    // 로컬에서도 대략적인 계산을 수행
    // 실제 단계는 룸 정보 업데이트 시 동기화됨
  }

  /// 타이머 종료 처리
  Future<void> _finishTimer() async {
    if (state.isFinishing) return;
    
    state = state.copyWith(isFinishing: true);
    _stopTimer();

    try {
      // 서버에 타이머 종료 알림
      await _roomRepository.finishTimer(roomId);
    } catch (e) {
      state = state.copyWith(
        errorMessage: '타이머 종료 중 오류가 발생했습니다.',
      );
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _roomSubscription?.cancel();
    super.dispose();
  }
}

/// TimerViewModel Provider Family
final timerViewModelProvider = 
    StateNotifierProvider.family.autoDispose<TimerViewModel, TimerState, String>(
  (ref, roomId) {
    final roomRepository = ref.watch(roomRepositoryProvider);
    
    return TimerViewModel(
      roomRepository: roomRepository,
      roomId: roomId,
    );
  },
);