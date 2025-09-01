# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development & Testing
```bash
# Run the app in debug mode
flutter run

# Run on specific device/emulator
flutter run -d <device_id>

# List available devices
flutter devices

# Build for release
flutter build apk  # Android
flutter build ios  # iOS

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Format code
dart format .

# Get dependencies
flutter pub get

# Clean build cache
flutter clean

# Upgrade dependencies
flutter pub upgrade

# Check outdated dependencies
flutter pub outdated
```

## Architecture Overview

Flowith is a collaborative study room app where friends share timers and grow virtual plants together through focused study sessions. The app emphasizes minimal design and collective achievement.

### Project Structure
```
lib/
├── main.dart                 # App entry point, Firebase init
├── firebase_options.dart     # Firebase platform configs
└── src/
    ├── core/                 # App-wide configurations
    │   ├── constants.dart    # App constants and enums
    │   └── theme.dart        # Material 3 theme config
    ├── data/                 # Data layer
    │   ├── models/
    │   │   ├── user_model.dart  # User profile with completedDates
    │   │   └── room_model.dart  # Room data with timer states
    │   └── repositories/
    │       ├── auth_repository.dart  # Google/Apple authentication
    │       └── room_repository.dart  # Room CRUD operations
    ├── features/             # Feature modules
    │   ├── auth/             # Authentication flow
    │   ├── home/             # Room creation/joining
    │   ├── room/             # Study room waiting area
    │   ├── timer/            # Active timer with plant growth
    │   ├── result/           # Session summary & sharing
    │   └── calendar/         # Habit tracking calendar
    └── shared/               # Reusable widgets
```

### State Management
Uses Riverpod 2.5.1 for reactive state management:
- `authStateProvider` - Firebase auth state changes
- `currentUserModelProvider` - Logged-in user data
- `roomStreamProvider(roomId)` - Real-time room updates
- `timerProvider` - Timer countdown state
- Each feature has its own ViewModel extending StateNotifier

### Firebase Integration
- **Authentication**: Google Sign-In, Apple Sign-In via Firebase Auth
- **Firestore Database Structure**:
  ```
  users/
    {userId}/
      - uid, email, displayName, photoURL
      - completedDates: List<DateTime>
  
  rooms/
    {roomId}/
      - id, name, hostId, createdAt
      - participants: List<UserModel>
      - timerMinutes, timerState (idle/running/finished)
      - startTime, currentPlantStage (0-10)
  ```
- **Real-time Updates**: Firestore streams for room synchronization
- **Security**: Host-only controls for timer management

### Key Technical Details
- **Timer States**: `idle` → `running` → `finished`
- **Plant Growth**: 11 stages (0-10), calculated as `(elapsed / total * 10).floor()`
- **Room Code**: 6-character alphanumeric for easy sharing
- **Share Feature**: Uses `share_plus` package for result cards
- **Calendar**: `table_calendar` package with custom event markers
- **Image Assets**: Located in `assets/images/` directory

### Dependencies
- State: flutter_riverpod 2.5.1
- Firebase: firebase_core 3.8.0, firebase_auth 5.3.3, cloud_firestore 5.5.0
- Auth: google_sign_in 6.2.2, sign_in_with_apple 6.1.3
- UI: table_calendar 3.1.2
- Utils: intl 0.19.0, share_plus 10.1.3, path_provider 2.1.5

### Development Notes
- App requires Firebase configuration (firebase_options.dart)
- Korean locale initialized for date formatting
- Material 3 design system with custom color scheme
- Linting: flutter_lints 5.0.0 with default rules