import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/room_model.dart';
import '../../../data/repositories/room_repository.dart';

/// Home 화면의 상태를 나타내는 클래스
class HomeState {
  final bool isCreatingRoom;
  final String? errorMessage;
  final List<RoomModel> userRooms;

  HomeState({
    this.isCreatingRoom = false,
    this.errorMessage,
    this.userRooms = const [],
  });

  HomeState copyWith({
    bool? isCreatingRoom,
    String? errorMessage,
    List<RoomModel>? userRooms,
  }) {
    return HomeState(
      isCreatingRoom: isCreatingRoom ?? this.isCreatingRoom,
      errorMessage: errorMessage,
      userRooms: userRooms ?? this.userRooms,
    );
  }
}

/// Home 화면의 비즈니스 로직을 처리하는 ViewModel
class HomeViewModel extends StateNotifier<HomeState> {
  final RoomRepository _roomRepository;

  HomeViewModel(this._roomRepository) : super(HomeState());

  /// 스터디 룸 생성
  Future<RoomModel?> createRoom(String roomName) async {
    // 룸 이름 검증
    if (roomName.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: '룸 이름을 입력해주세요.',
      );
      return null;
    }

    // 로딩 상태 시작
    state = state.copyWith(isCreatingRoom: true, errorMessage: null);

    try {
      // 룸 생성
      final room = await _roomRepository.createRoom(roomName.trim());
      
      // 성공
      state = state.copyWith(
        isCreatingRoom: false,
        errorMessage: null,
      );
      
      return room;
    } catch (e) {
      // 실패
      state = state.copyWith(
        isCreatingRoom: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// 룸 참여 (deep link를 통해 룸 ID를 받았을 때)
  Future<RoomModel?> joinRoom(String roomId) async {
    state = state.copyWith(errorMessage: null);

    try {
      final room = await _roomRepository.joinRoom(roomId);
      return room;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// HomeViewModel Provider
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final roomRepository = ref.watch(roomRepositoryProvider);
  return HomeViewModel(roomRepository);
});