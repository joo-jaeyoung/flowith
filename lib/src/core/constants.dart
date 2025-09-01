/// Flowith 앱 전체에서 사용되는 상수 정의
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // 앱 정보
  static const String appName = 'Flowith';
  static const String appTagline = '함께 몰입하는 시간';
  
  // 타이머 프리셋 (초 단위)
  static const int timerPreset10Min = 600;   // 10분
  static const int timerPreset25Min = 1500;  // 25분 (뽀모도로)
  static const int timerPreset50Min = 3000;  // 50분
  
  // 최소/최대 제한
  static const int minParticipants = 1; // 타이머 시작을 위한 최소 참여자 수
  static const int maxParticipants = 10; // 룸당 최대 참여자 수
  static const int maxRoomNameLength = 30; // 룸 이름 최대 길이
  
  // 애니메이션 시간
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration normalAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // 패딩 값
  static const double kDefaultPadding = 16.0;
  static const double kSmallPadding = 8.0;
  static const double kLargePadding = 24.0;
  static const double kExtraLargePadding = 32.0;
  
  // Border Radius
  static const double kSmallRadius = 8.0;
  static const double kDefaultRadius = 12.0;
  static const double kLargeRadius = 16.0;
  static const double kCircularRadius = 100.0;
  
  // 아이콘 크기
  static const double kSmallIconSize = 16.0;
  static const double kDefaultIconSize = 24.0;
  static const double kLargeIconSize = 32.0;
  static const double kExtraLargeIconSize = 48.0;
  
  // 식물 성장 단계
  static const int plantStages = 11; // 0단계(씨앗)부터 10단계(완전 성장)까지
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String roomsCollection = 'rooms';
  
  // Room States
  static const String roomStateIdle = 'idle';
  static const String roomStateRunning = 'running';
  static const String roomStateFinished = 'finished';
  
  // Asset Paths
  static const String logoPath = 'assets/images/logo.png';
  static const String plantStage0Path = 'assets/images/plant_stage_0.png';
  static const String plantStage1Path = 'assets/images/plant_stage_1.png';
  static const String plantStage2Path = 'assets/images/plant_stage_2.png';
  static const String plantStage3Path = 'assets/images/plant_stage_3.png';
  static const String plantStage4Path = 'assets/images/plant_stage_4.png';
  static const String plantStage5Path = 'assets/images/plant_stage_5.png';
  static const String plantStage6Path = 'assets/images/plant_stage_6.png';
  static const String plantStage7Path = 'assets/images/plant_stage_7.png';
  static const String plantStage8Path = 'assets/images/plant_stage_8.png';
  static const String plantStage9Path = 'assets/images/plant_stage_9.png';
  static const String plantStage10Path = 'assets/images/plant_stage_10.png';
  
  // 식물 이미지 경로를 stage 번호로 가져오기
  static String getPlantImagePath(int stage) {
    if (stage < 0 || stage > 10) {
      return plantStage0Path;
    }
    return 'assets/images/plant_stage_$stage.png';
  }
  
  // Deep Link
  static const String deepLinkScheme = 'flowithapp';
  static const String deepLinkRoomPath = 'room';
  
  // Error Messages
  static const String errorGeneric = '오류가 발생했습니다. 다시 시도해주세요.';
  static const String errorNetworkConnection = '네트워크 연결을 확인해주세요.';
  static const String errorRoomNotFound = '룸을 찾을 수 없습니다.';
  static const String errorAuthFailed = '로그인에 실패했습니다.';
  static const String errorMinParticipants = '최소 1명 이상이 참여해야 시작할 수 있습니다.';
  static const String errorRoomFull = '룸이 가득 찼습니다.';
  
  // Success Messages
  static const String successRoomCreated = '룸이 생성되었습니다.';
  static const String successTimerStarted = '타이머가 시작되었습니다.';
  static const String successImageSaved = '이미지가 저장되었습니다.';
  static const String successShared = '공유되었습니다.';
  
  // Placeholder Text
  static const String placeholderRoomName = '룸 이름을 입력하세요';
  static const String placeholderSearchRoom = '룸 코드를 입력하세요';
}