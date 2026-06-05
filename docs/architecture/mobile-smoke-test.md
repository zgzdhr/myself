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

## Phase 3 A5 Real API Debug Note

Date: 2026-06-05
Scope: iOS simulator real API smoke debugging

Evidence gathered:

- `curl http://127.0.0.1:8787/health` returned `{"ok":true}`.
- Direct `curl /parse` calls returned valid structured JSON for:
  - `明天上午联系王总，我今天有点累。`
  - `我上午效率比较低。`
  - `番茄炒蛋怎么做会更好吃？`
- The running Flutter build used `--dart-define=API_BASE_URL=http://127.0.0.1:8787`, while the mobile code previously read only `PARSER_BASE_URL`.
- The input page rendered `afterInput` home content before parser results, so after tapping `整理`, the assistant reply and extracted cards could appear below the home suggestion cards and look like no result was shown.

Fixes added:

- Mobile parser base URI now accepts both `PARSER_BASE_URL` and `API_BASE_URL`; `PARSER_BASE_URL` remains the preferred name, and `API_BASE_URL` is a compatibility alias for smoke runs.
- Parser feedback now appears directly below the input panel before home follow-up content.

Verification:

```bash
cd /Users/mac/projects/cc/myself/apps/mobile
flutter analyze
flutter test
```

## Phase 3 A5 Real DeepSeek + iOS Manual Smoke

Date: 2026-06-05
Scope: iOS simulator with real DeepSeek API via local proxy

### P0: Latin-1 Encoding Bug

Found and fixed during A5 manual smoke. Root cause:

`HttpParserClient._defaultPostJson` used `request.write(body)` which defaults
to **Latin-1 encoding**. Any Chinese text in the JSON body caused
`UnicodeSubsetEncoder.convert` to throw `Invalid argument: Contains invalid
characters`, which was caught as a generic `network_error` showing the
user-facing failure message.

Fix: `request.add(utf8.encode(body))` — explicit UTF-8 encoding.

Additionally, `NSAppTransportSecurity.NSAllowsLocalNetworking` was added to
`ios/Runner/Info.plist` to allow HTTP requests to `127.0.0.1:8787` from the
iOS simulator (ATS blocks non-standard HTTP ports by default).

### Manual Smoke Observations

App built and launched on iPhone 17 iOS simulator, connected to live DeepSeek
API proxy at `http://127.0.0.1:8787`. After the encoding fix, parser requests
succeeded and extracted item cards appeared.

User-reported issues during manual smoke:

| Input | Result | Notes |
|---|---|---|
| 上午要和领导吃饭，很难受 | ✓ task_create + short_term_state | Multi-intent correctly parsed |
| 不和领导吃饭了，取消了 | ✗ No task_update triggered | Should match and cancel the original task |

### Known Quality Gap: task_update Matching

"不和领导吃饭了，取消了" should trigger `task_update` (cancel action) but
the DeepSeek parser did not classify it as such. Two layers involved:

1. **Parser classification** — DeepSeek needs to recognize取消/不...了/etc.
   as task_update cancel semantics. The parser sample set already has cancel
   examples (`task_update_cancel`), but real-world phrasing varies.
2. **Task matching** — Even if correctly classified, the cancel action must
   find the target task ("上午要和领导吃饭"). This is the job of
   `ExtractedItemsController.applyTaskUpdate` and ContextBuilder.

These issues will be addressed in Phase 3 **B phase** (B1-B4: task_update
rule tightening and ContextBuilder expansion), not in the A phase.

### A5 Verification

```bash
cd /Users/mac/projects/cc/myself/apps/mobile
flutter analyze  # No issues found
flutter test     # 69 pass / 0 fail

cd /Users/mac/projects/cc/myself/apps/api
npm run typecheck  # pass
npm test           # 45 pass / 0 fail
```
