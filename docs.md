[AI Development Agent Task Document: 'Flowith' MVP]
Version: 1.0
Project Name: Flowith
Target Framework: Flutter
Objective: This document contains the complete specification for the Minimum Viable Product (MVP) of the 'Flowith' mobile application. AI Agent, you are instructed to develop the application based solely on this document. Adhere strictly to the specified technical stack and development conventions.
Part 1: Core Directives & Technical Specifications
1.1. Primary Instructions for AI Agent
Single Source of Truth: This document is the single source of truth for all development tasks. Do not infer features or logic not specified herein.
Technology Stack: The application MUST be developed using Flutter with the Dart language.
Backend Integration: All backend services, including authentication and real-time database, MUST use Google Firebase.
State Management: The application's state MUST be managed using the flutter_riverpod package.
Code Conventions: All generated code MUST strictly follow the conventions outlined in Part 2.
Asset Generation: For required image assets, use appropriate placeholders if final assets are not provided. Log a requirement for each needed asset.
1.2. Technical Stack
Framework: Flutter (latest stable version)
Language: Dart (latest stable version)
State Management: flutter_riverpod
Backend: Firebase
Authentication: Firebase Authentication (Google Sign-In, Apple Sign-In)
Database: Cloud Firestore for real-time data synchronization.
Required Libraries (pubspec.yaml):
flutter_riverpod
firebase_core
firebase_auth
google_sign_in
sign_in_with_apple
cloud_firestore
share_plus (for sharing functionality)
path_provider & image_gallery_saver (for saving result cards)
intl (for date formatting in the calendar)
Part 2: Flutter Development Conventions
2.1. Naming Conventions
Files: Use snake_case (e.g., study_room_view.dart).
Classes & Enums: Use UpperCamelCase (e.g., StudyRoomView, TimerState).
Variables, Methods, Functions: Use lowerCamelCase (e.g., userName, startTimer()).
Constants: Use k prefix followed by lowerCamelCase (e.g., kDefaultPadding).
2.2. Project Structure (Feature-First)
Organize the lib directory as follows:
code
Code
lib/
├── main.dart
└── src/
    ├── core/                  # Core logic, constants, theme
    │   ├── theme.dart
    │   └── constants.dart
    ├── data/                  # Data layer
    │   ├── models/            # Data models (e.g., user_model.dart)
    │   └── repositories/      # Data repositories (e.g., auth_repository.dart)
    ├── features/              # Feature-based modules
    │   ├── auth/
    │   │   ├── view/
    │   │   └── viewmodel/
    │   ├── home/
    │   │   └── ...
    │   ├── room/
    │   │   └── ...
    │   └── calendar/
    │       └── ...
    └── shared/                # Shared widgets, providers, etc.
        ├── providers/
        └── widgets/
2.3. Code Style & State Management
Formatting: Run dart format . before committing.
Linting: Use flutter_lints with default rules.
Widgets: Decompose UI into small, reusable widgets. Use const constructors wherever possible for performance optimization.
State Management (Riverpod):
Use Provider for exposing dependency-injected services (e.g., repositories).
Use FutureProvider for one-time asynchronous data fetching.
Use StreamProvider for real-time data streams from Firestore.
Use StateNotifierProvider for managing complex UI state that can change over time.
Part 3: Data Models (Firestore Schema)
3.1. users collection
Document ID: Firebase Auth UID
Fields:
uid: String
displayName: String
email: String
photoUrl: String (URL)
createdAt: Timestamp
completedDates: List<Timestamp> (List of dates where at least one session was completed)
3.2. rooms collection
Document ID: Auto-generated
Fields:
roomId: String
roomName: String
hostUid: String (UID of the user who created the room)
participants: List<Map<String, String>> (e.g., [{'uid': '...', 'displayName': '...'}, ...])
timerState: String (idle, running, finished)
setDurationSeconds: int (Total duration of the timer in seconds)
startTime: Timestamp (null if idle)
endTime: Timestamp (null if idle)
createdAt: Timestamp
Part 4: Screen & Feature Specifications
S-01: Authentication View (auth_view.dart)
Purpose: To allow new and existing users to sign in.
UI Components:
Asset: App Logo (assets/images/logo.png)
Text: Service Catchphrase ("함께 몰입하는 시간")
Button (Google): Icon + "Google로 계속하기" Text
Button (Apple): Icon + "Apple로 계속하기" Text
Functional Logic:
On tap Button (Google):
Trigger Firebase Google Authentication flow via AuthRepository.
On success:
Check if the user document exists in the users collection.
If not, create a new document using the user's Auth data.
Navigate to S-02: HomeView.
On failure: Display a SnackBar with an error message.
On tap Button (Apple): Implement similar logic for Apple Sign-In.
S-02: Home View (home_view.dart)
Purpose: The main entry point after login. Allows users to create or join a room.
UI Components:
AppBar: Title "Flowith", IconButton for navigating to S-06: CalendarView.
ElevatedButton: "스터디 룸 만들기"
Functional Logic:
On tap "스터디 룸 만들기":
Show a dialog (AlertDialog) asking for the room name.
On confirming the name, create a new document in the rooms collection with the current user as the host and timerState: 'idle'.
Navigate to S-03: StudyRoomView, passing the newly created roomId.
S-03: Study Room View (study_room_view.dart)
Purpose: A waiting area before the timer starts. Allows the host to start the timer and all users to invite others.
UI Components:
AppBar: Displays roomName. IconButton to exit the room.
Text: "참여 중인 친구들"
ListView: Displays the displayName of all users in the participants list.
Asset: Central image of a seed (assets/images/plant_stage_0.png).
Row of OutlinedButtons (for Host only): "10분", "25분", "50분" presets.
ElevatedButton (for Host only): "시작하기". Disabled if participant count < 2.
ElevatedButton (for all): "친구 초대하기"
Functional Logic:
Data: Use StreamProvider to listen for real-time changes to the current room document in Firestore.
Host Logic:
Tapping a preset button sets the setDurationSeconds variable.
On tap "시작하기":
Update the room document in Firestore:
timerState -> 'running'
startTime -> FieldValue.serverTimestamp()
endTime -> Calculated timestamp (now + setDurationSeconds)
The StreamProvider will automatically rebuild the UI and navigate all users to the S-04: TimerView.
All Users Logic:
On tap "친구 초대하기":
Generate a unique deep link for the room (e.g., flowithapp://room?id=<roomId>).
Use the share_plus package to open the OS share sheet with the link.
On tap Exit: Remove the user from the participants list in Firestore. If the user is the host, delete the room document. Navigate back to S-02: HomeView.
S-04: Timer View (timer_view.dart)
Purpose: The main focus screen where the shared timer runs.
UI Components:
Text: Large font displaying the remaining time (MM:SS).
AnimatedSwitcher or similar widget: Displays the plant image, which changes based on progress.
Text: "함께 집중하는 중..."
Row: A series of small CircleAvatar widgets for each participant.
Functional Logic:
Data: Continue using the StreamProvider from S-03.
Timer Display:
Calculate remaining seconds: room.endTime.toDate().difference(DateTime.now()).inSeconds.
Format and display the remaining time. Update every second using a local Timer.
If remaining time <= 0, update the room document's timerState to 'finished'. This will trigger navigation to S-05: ResultView.
Plant Growth Animation:
Calculate progress: (elapsedSeconds / setDurationSeconds) * 100.
Display the corresponding plant image based on progress.
Required assets: plant_stage_0.png through plant_stage_10.png.
Logic: If progress is 0-9%, show stage 1. 10-19%, show stage 2, etc.
S-05: Result View (result_view.dart)
Purpose: To show the result of a completed session and allow sharing.
UI Components:
A container widget styled as a "card" (result_card.dart). This card should contain:
The final, fully grown plant image (plant_stage_10.png).
Text: "함께 [XX:XX]분을 집중했어요!"
Text: Today's date.
ListView: List of participant displayNames.
Asset: "Flowith" logo at the bottom.
Button: "이미지로 저장하기"
Button: "공유하기"
Button: "닫기"
Functional Logic:
Data: When this screen loads, the host updates the current user's completedDates list in their user document in Firestore with today's date (if not already present).
On tap "이미지로 저장하기": Convert the result_card widget to an image and save it to the device's gallery using image_gallery_saver.
On tap "공유하기": Convert the card to an image and share it using share_plus.
On tap "닫기": Navigate back to S-02: HomeView. The host should also update the room's timerState back to 'idle' or delete the room.
S-06: Calendar View (calendar_view.dart)
Purpose: To show the user's record of successful focus sessions.
UI Components:
AppBar: "나의 집중 기록"
A calendar widget (can be built custom or use a package like table_calendar).
Functional Logic:
Data: Fetch the current user's completedDates list from their document in Firestore.
Display: For each date in the completedDates list, display a 'plant' icon or highlight the date cell in the calendar UI.