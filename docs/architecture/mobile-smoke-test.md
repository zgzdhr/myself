# Mobile Smoke Test

Date: 2026-06-01  
Scope: Task 12 Android / iOS smoke verification

## Summary

- Result: Blocked by local development environment, not by application code.
- Flutter project status: Android and iOS project directories exist.
- Connected runnable targets found locally: macOS desktop and Chrome web only.
- Android simulator: unavailable because Android SDK / emulator sources are not installed.
- iOS simulator: unavailable because full Xcode setup and CocoaPods are not installed.

## Commands Run

```bash
cd apps/mobile
flutter devices
flutter emulators
flutter doctor
flutter run -d android
flutter run -d ios
```

## Android

- Device: Not available.
- Result: Not run.
- Blocking reason: `flutter doctor` reports Android SDK is missing, and `flutter emulators` reports no emulator sources.
- Observed `flutter run -d android` result: no supported device found with name or id matching `android`.
- Next setup step: install Android Studio, complete Android SDK setup, create an Android Virtual Device, then rerun `flutter run -d android`.

## iOS

- Device: Not available.
- Result: Not run.
- Blocking reason: `flutter doctor` reports full Xcode installation is incomplete and CocoaPods is not installed.
- Observed `flutter run -d ios` result: no supported device found with name or id matching `ios`.
- Next setup step: install full Xcode from the App Store, run Xcode first-launch setup, install CocoaPods, create/open an iOS Simulator, then rerun `flutter run -d ios`.

## Expected Manual Smoke Flow

After Android or iOS simulator is available:

1. Start the mobile app with `flutter run -d android` or `flutter run -d ios`.
2. Open the input page.
3. Submit a sample natural-language input, for example: `明天提醒我联系客户，最近我有点累，我喜欢直接一点的建议`.
4. Confirm that extracted item cards appear.
5. Confirm at least one task, one short-term state, and one profile candidate.
6. Return to the home page and confirm that simple suggestions use confirmed records.
7. Open memory management pages and confirm records can be viewed, edited where supported, rejected, or deleted.

## Notes

- This task intentionally does not enable macOS desktop support because the product target is Android and iOS.
- The current app still uses mock parser behavior in the mobile client by default, which is appropriate for first smoke testing the local UI and database loop.
- Real API-device testing will need a device-safe API base URL configuration later. Android emulators usually cannot call the host machine through `localhost`; they commonly need `10.0.2.2`.
