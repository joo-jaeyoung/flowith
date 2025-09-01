import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/constants.dart';

/// Study Room 화면의 상태를 나타내는 클래스
class StudyRoomState {
  final bool isLoading;
  final String? errorMessage;
  final int selectedDuration; // 선택된 타이머 시간 (초)

  StudyRoomState({
    this.isLoading = false,
    this.errorMessage,
    this.selectedDuration = AppConstants.timerPreset25Min,
  });

  StudyRoomState copyWith({
    bool? isLoading,
    String? errorMessage,
    int? selectedDuration,
  }) {
    return StudyRoomState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedDuration: selectedDuration ?? this.selectedDuration,
    );
  }
}

/// Study Room 화면의 비즈니스 로직을 처리하는 ViewModel
class StudyRoomViewModel extends StateNotifier<StudyRoomState> {
  final RoomRepository _roomRepository;
  final String roomId;

  StudyRoomViewModel({
    required RoomRepository roomRepository,
    required AuthRepository authRepository,
    required this.roomId,
  })  : _roomRepository = roomRepository,
        super(StudyRoomState());

  /// 타이머 시간 설정
  void setDuration(int seconds) {
    state = state.copyWith(selectedDuration: seconds);
  }

  /// 타이머 시작
  Future<bool> startTimer() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _roomRepository.startTimer(roomId, state.selectedDuration);
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 룸 나가기
  Future<void> leaveRoom() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _roomRepository.leaveRoom(roomId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// 친구 초대 (딥링크 공유)
  Future<void> inviteFriends() async {
    try {
      // 딥링크 생성
      final deepLink = '${AppConstants.deepLinkScheme}://${AppConstants.deepLinkRoomPath}?id=$roomId';
      
      // 공유 메시지
      const message = '함께 집중해요! Flowith 스터디 룸에 참여하세요 🌱\n';
      
      // 공유
      await Share.share(
        '$message$deepLink',
        subject: 'Flowith 스터디 룸 초대',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: '공유 중 오류가 발생했습니다.',
      );
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// StudyRoomViewModel Provider Family
final studyRoomViewModelProvider = 
    StateNotifierProvider.family<StudyRoomViewModel, StudyRoomState, String>(
  (ref, roomId) {
    final roomRepository = ref.watch(roomRepositoryProvider);
    final authRepository = ref.watch(authRepositoryProvider);
    
    return StudyRoomViewModel(
      roomRepository: roomRepository,
      authRepository: authRepository,
      roomId: roomId,
    );
  },
);