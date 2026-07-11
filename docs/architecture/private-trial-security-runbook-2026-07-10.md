# Private trial security runbook

Date: 2026-07-10
Status: source implementation, full automated tests, and unsigned/debug native
builds pass; live Supabase/Vercel and true-device verification are still
required.

## Scope and decisions

This is a private trial, not a public release. The agreed boundaries are:

- Email OTP login is required before the app can call DeepSeek through
  `/parse`, `/review`, or `/plan`.
- Login itself does not automatically upload local records.
- Calendar scheduling, daily recurrence, and sedentary-session data are
  local-only, even during the existing manual cloud sync.
- A signed-in user can explicitly delete their entire Supabase cloud copy; the
  action is confirmed and never deletes the local SQLite database.
- Android system backup is disabled for this privacy-sensitive private build.
- The current release is not app-store ready: it still has the placeholder
  application id. Android release builds now require an explicit private
  signing configuration and no longer fall back to the debug key.

## Configure the API safely

Set these server-side environment variables on the local API proxy and on the
deployment host. They must not be passed to Flutter except for the two
publishable mobile values below.

```text
DEEPSEEK_API_KEY=...
DEEPSEEK_BASE_URL=https://api.deepseek.com
DEEPSEEK_MODEL=deepseek-v4-flash
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
API_PORT=8787
```

The API verifies `Authorization: Bearer <Supabase access token>` at Supabase
Auth. The server uses only the publishable key for that verification; a
service-role key is neither needed nor allowed in the mobile app.

The API deliberately fails closed when its Supabase authentication settings are
missing: it must not be deployed as a public DeepSeek proxy without that gate.
It has a 60-request-per-minute pre-auth IP burst guard, a 20-request-per-minute
per-user per-instance burst guard, and a durable 30-request-per-UTC-day quota.
The daily counter is a Supabase RPC executed with the caller's own JWT; it is
atomic and does not require a service-role key. Vercel uses one trusted proxy
hop automatically; a self-hosted deployment must set `TRUST_PROXY_HOPS` to its
actual proxy depth before relying on IP buckets.

Before deploying this API change, apply
`docs/architecture/supabase/migrations/20260711_private_trial_security.sql` to
an existing Phase 5A trial project. Use the full
`docs/architecture/supabase/phase-5a-schema.sql` only when creating a fresh
project from scratch.
If the quota RPC is absent or unavailable, the API intentionally returns 503
instead of allowing an unmetered paid-AI call.

## Build the private-trial APK

Use HTTPS for a remote endpoint. Only debug builds may call a local HTTP API
proxy on the same LAN; the release manifest now denies cleartext traffic.
Release builds have no hard-coded production fallback: omitting
`PARSER_BASE_URL` deliberately disables AI calls rather than sending data to a
historic public proxy.

```bash
cd apps/mobile
flutter build apk --debug \
  --dart-define=PARSER_MODE=http \
  --dart-define=PARSER_BASE_URL=https://<api-host> \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=APP_LOCK_ENABLED=true
```

For a local-LAN debug proxy, replace `PARSER_BASE_URL` with the Mac LAN URL
such as `http://192.168.x.x:8787`. Do not use that HTTP URL in a release build.

## True-device checklist

1. Install the debug APK and open “我的”.
2. Complete email OTP login; do not press manual cloud sync yet.
3. Submit one AI input. It should succeed only after login; sign out and retry
   to confirm the client blocks the request before it reaches DeepSeek.
   Use a disposable test account to confirm the 31st authenticated AI request in a UTC
   day returns `daily_quota_exhausted` (429), while a burst over 20 requests in
   one minute returns `rate_limited` (429).
4. Generate one review and one time-plan draft while signed in.
5. Create a timed task, a daily recurring task, and a sedentary session. Press
   manual cloud sync, then verify that no new `schedule_plans`,
   `schedule_blocks`, or local-only task schedule values were uploaded.
6. With disposable test data only, use “删除云端副本” and verify that all rows
   for the test user disappear from the Supabase tables, including any old
   `schedule_*` rows. Confirm the phone still shows its local records.
7. Restart the app and confirm that the session restores only after the
   device-level app lock succeeds. Verify that canceling device authentication
   never reveals the app content. Reinstalling the app should require a new
   email OTP login.
8. Confirm that API and app logs contain no task, state, profile, or OTP text.

## Known blockers before broader distribution

- Secure session storage and app-lock source code compile in Android/iOS native
  builds and have automated coverage, but true-device behavior has not yet been
  verified. Do not describe the protection as release-ready until this
  checklist passes.
- Android release builds no longer use debug signing, but a private production
  key has not been created and the app still uses `com.example.mobile`.
- The Supabase SQL draft now adds owner-reference triggers, delete grants, and
  an anonymous-role revoke, plus the durable daily-quota RPC. These protections
  and the cloud-copy deletion flow must be applied and tested against the live
  project before broader use.
- Automated tests now pass (Flutter 171, API 90). Physical Android/iOS testing
  remains required because no phone was connected on 2026-07-11.
