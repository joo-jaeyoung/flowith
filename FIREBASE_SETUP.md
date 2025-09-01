# Firebase 설정 가이드

## ✅ 완료된 작업

1. **Firebase 프로젝트 연결**
   - 프로젝트 ID: `flowith-7b114`
   - `flutterfire configure` 실행 완료
   - `firebase_options.dart` 파일 생성 완료

2. **코드 수정**
   - `main.dart`에 Firebase 초기화 코드 추가
   - Mock 모드를 `false`로 변경하여 실제 Firebase 사용

3. **플랫폼 설정 파일**
   - iOS: `GoogleService-Info.plist` 존재 확인
   - Android: `google-services.json` 존재 확인

## 🔧 Firebase Console에서 필요한 추가 설정

### 1. Authentication 설정
Firebase Console에서 다음을 활성화해야 합니다:

1. [Firebase Console](https://console.firebase.google.com/project/flowith-7b114/authentication) 접속
2. **Sign-in method** 탭 클릭
3. 다음 제공업체 활성화:
   - **Google** 
     - 활성화 토글 ON
     - 프로젝트 지원 이메일 설정
   - **Apple** (iOS만 해당)
     - 활성화 토글 ON
     - Apple Developer Account 필요

### 2. Firestore Database 설정
1. [Firestore Database](https://console.firebase.google.com/project/flowith-7b114/firestore) 접속
2. **데이터베이스 만들기** 클릭
3. 프로덕션 모드 선택
4. 리전 선택 (권장: `asia-northeast3` - 서울)
5. **Rules** 탭에서 `firestore.rules` 파일 내용 복사하여 붙여넣기

### 3. iOS 추가 설정 (iOS 개발 시)
1. Xcode에서 프로젝트 열기:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Runner** > **Info** > **URL Types** 추가:
   - URL Schemes: `GoogleService-Info.plist`의 `REVERSED_CLIENT_ID` 값

3. **Info.plist**에 추가:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```

### 4. Android 추가 설정 (Android 개발 시)
1. SHA-1 또는 SHA-256 지문 추가:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   
2. Firebase Console에서:
   - 프로젝트 설정 > Android 앱 > SHA 인증서 지문 추가

## 🚀 앱 실행

### iOS 실행
```bash
flutter run -d ios
```

### Android 실행
```bash
flutter run -d android
```

### 웹 실행 (현재 미지원)
웹 플랫폼은 현재 설정되지 않았습니다.

## ⚠️ 주의사항

1. **첫 실행 시 오류가 발생할 수 있습니다**
   - Firebase Console에서 Authentication과 Firestore를 활성화했는지 확인
   - 플랫폼별 설정 파일이 올바른 위치에 있는지 확인

2. **Google Sign-In 테스트**
   - iOS: 시뮬레이터에서 작동하지 않을 수 있음 (실제 기기 권장)
   - Android: 에뮬레이터에서도 작동

3. **Apple Sign-In 테스트**
   - Apple Developer Account 필요
   - iOS 13.0 이상 필요

## 📝 문제 해결

### Firebase 초기화 오류
```
Firebase initialization error
```
- Firebase Console에서 프로젝트가 활성화되었는지 확인
- 인터넷 연결 확인

### Authentication 오류
```
Sign in failed
```
- Firebase Console에서 해당 로그인 방법이 활성화되었는지 확인
- 플랫폼별 설정이 완료되었는지 확인

### Firestore 권한 오류
```
Permission denied
```
- Firestore 보안 규칙이 올바르게 설정되었는지 확인
- 사용자가 로그인되어 있는지 확인