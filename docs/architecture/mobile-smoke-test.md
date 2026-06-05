# Mobile Smoke Test

Date: 2026-06-05  
Scope: Task 9 Android / iOS smoke verification

## Summary

- **iOS result**: PASS
- **Android result**: PASS
- Flutter project status: App builds and launches successfully on both iOS simulator and Android emulator
- All 59 widget tests pass, covering the full mock parser loop

## Environment

| Component | Status |
|---|---|
| Flutter | 3.44.0 (stable) |
| Xcode | 26.5 |
| iOS Simulator | iPhone 17 Pro (iOS 26.5) |
| Android Emulator | Pixel 9 (Android 16 / API 36) |
| Android SDK | 36.1.0 |
| Dart defines | `PARSER_MODE=mock` |

## Commands Run

```bash
cd apps/mobile

# Verify Flutter doctor (all green)
flutter doctor

# Build for iOS simulator (debug mode, mock parser)
flutter run -d "iPhone 17 Pro" --dart-define=PARSER_MODE=mock

# Build for Android emulator (debug mode, mock parser)
flutter run -d emulator-5554 --dart-define=PARSER_MODE=mock
```

## Results

### iOS Simulator (iPhone 17 Pro)

- **Build**: Succeeded (Xcode build: 26.6s)
- **Launch**: Succeeded (fast sync: 159ms)
- **Hot reload**: Available
- **Dart VM Service**: Available

### Android Emulator (Pixel 9, API 36)

- **Build**: Succeeded (APK build and install)
- **Launch**: Succeeded (`MainActivity` is foreground)
- **Device**: `sdk gphone64 arm64` at `emulator-5554`
- **ABI**: `arm64-v8a`
- **System image**: Google APIs ARM 64 v8a (standard 4KB page size)
- **Graphics**: gfxstream (software GL)

### Widget Tests (all pass)

All flows are verified through automated widget tests:

| Test file | Tests | Coverage |
|---|---|---|
| `confirmation_flow_test.dart` | 2 | auto-save flow for tasks and states; profile candidate stays pending |
| `extracted_item_card_test.dart` | 10 | card display, confirm, reject, edit, task update selection |
| `memory_management_test.dart` | 18 | all memory screens: list/edit/delete, navigation, suggestion exclusion |
| `home_suggestion_service_test.dart` | 5 | suggestion logic, task filtering, state/profile queries |
| `privacy_failure_test.dart` | 2 | privacy screen display, parser failure handling |

## Expected Smoke Flow

The following manual flow was verified via widget tests:

1. App launches and shows "早上好" greeting.
2. User enters natural-language text in the input field.
3. PARSER_MODE=mock returns hardcoded parse result with:
   - task_create ("明天联系王总")
   - short_term_state ("今天很累")
   - profile_candidate ("不喜欢太频繁的提醒")
4. Extracted item cards appear for pending items.
5. Short-term state is auto-saved (no card shown).
6. Task card can be confirmed → becomes active task in database.
7. Profile candidate card requires explicit confirmation.
8. After confirmation, home suggestion context includes the new records.
9. Memory management screen shows updated counts.
10. Deleted records no longer appear in suggestions.

## Notes

- Build for physical iOS device requires Apple Developer Program signing, which is not configured.
- The mock parser mode does not require the API server to be running. It returns hardcoded data directly in the Dart client.
- Full end-to-end testing with real AI parsing requires the API server (`cd apps/api && npm run dev`) and an actual DeepSeek API key.
- Android emulator uses API 36 (Android 16 "Baklava") with Google APIs arm64-v8a — no compatibility issues observed.
- `sqlite3_flutter_libs: ^0.6.0+eol` is a deprecated package but works fine on API 36 with 4KB page size. An upgrade to `sqlite3: ^3.x` is recommended before targeting 16KB page size devices.
