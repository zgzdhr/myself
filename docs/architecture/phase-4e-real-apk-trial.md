# Phase 4E Real APK Trial Chain

Date: 2026-06-09
Scope: Android debug APK + local API proxy + DeepSeek parser trial

## Goal

Make the real-device trial repeatable:

```text
Flutter debug APK
-> Android phone on the same LAN as the Mac
-> local TypeScript API proxy
-> DeepSeek parser
-> validated JSON
-> local SQLite memory
```

Phase 4E does not add cloud sync, accounts, release signing, or production
deployment. It stabilizes the test chain so real usage feedback is trustworthy.

## Current Result

- Android debug builds are allowed to make HTTP requests to a local API proxy.
- The mobile app accepts `PARSER_BASE_URL` and the older `API_BASE_URL` alias.
- DeepSeek API key stays on the API server and is not shipped in the APK.
- The API proxy exposes `/health` for network checks and `/parse` for real
  parser requests.
- Phase 4D.5 task state changes are included in the same trial baseline:
  completed/cancelled tasks stay visible but no longer participate in
  suggestions or task-update matching.

## Required Local Environment

API server environment, stored locally and not committed:

```bash
cd apps/api

DEEPSEEK_API_KEY=replace_with_real_key
DEEPSEEK_BASE_URL=https://api.deepseek.com
DEEPSEEK_MODEL=deepseek-v4-flash
API_PORT=8787
```

The phone and Mac must be on the same network. The phone cannot use
`127.0.0.1` to reach the Mac; it must use the Mac LAN IP, for example
`http://192.168.0.103:8787`.

## Start The API Proxy

```bash
cd apps/api
npm run dev
```

Health checks:

```bash
curl http://127.0.0.1:8787/health
curl http://<mac-lan-ip>:8787/health
```

Expected result:

```json
{"ok":true}
```

If localhost works but LAN IP fails, check the Mac firewall, Wi-Fi network, and
whether the phone is on the same LAN.

## Build A Real-API Debug APK

```bash
cd apps/mobile
flutter build apk --debug \
  --dart-define=PARSER_MODE=http \
  --dart-define=PARSER_BASE_URL=http://<mac-lan-ip>:8787
```

APK output:

```text
apps/mobile/build/app/outputs/flutter-apk/app-debug.apk
```

Install with Android Debug Bridge:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Android Network Contract

The Android manifest includes:

- `android.permission.INTERNET`
- `android:usesCleartextTraffic="true"`

This is acceptable for local debug trials because the app calls a local HTTP API
proxy on the same LAN. It is not the final production security posture.

Before production or broader distribution:

- use HTTPS for any remote API endpoint;
- avoid broad cleartext traffic if possible;
- keep `DEEPSEEK_API_KEY` server-side only;
- separate debug and release network configuration.

## Smoke Inputs

After installing the APK and starting the API proxy, test:

```text
明天上午联系王总，我今天有点累。
下午开会的事情取消了。
今天好累，健身不想去了。
```

Expected checks:

- The first input creates a task and short-term state.
- The cancellation inputs generate `task_update` cards and require confirmation.
- Confirmed completed/cancelled tasks remain visible in the task memory page
  with status labels.
- Completed/cancelled tasks no longer appear in homepage suggestions.
- API logs should not print raw personal input text.

## Troubleshooting Order

1. API proxy health: `curl http://127.0.0.1:8787/health`.
2. LAN reachability: `curl http://<mac-lan-ip>:8787/health`.
3. DeepSeek key: verify `DEEPSEEK_API_KEY` is set only in `apps/api`.
4. APK define: confirm `PARSER_BASE_URL` uses the Mac LAN IP, not localhost.
5. Android install: reinstall with `adb install -r`.
6. Parser behavior: run `cd apps/api && npm run smoke:parse`.
7. Mobile logs: use `flutter logs` or Android Studio logcat for client errors.

## Exit Criteria

Phase 4E is considered complete when:

- API proxy can be reached from both localhost and LAN IP.
- A debug APK can be built with a real `PARSER_BASE_URL`.
- The APK can submit real inputs through the API proxy.
- The API key is not present in mobile code or APK build defines.
- The real-device trial steps are documented enough to repeat later.
