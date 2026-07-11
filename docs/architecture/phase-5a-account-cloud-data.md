# Phase 5A Account and Cloud Data

Date: 2026-06-18, updated 2026-06-22

Status: first account implementation plus first one-way cloud sync complete;
cloud-copy deletion is implemented in source and awaits live Supabase/device
verification.
This document records the account and cloud-data boundary that new sessions
should follow.

## 1. What Phase 5A Implements

Phase 5A moves the app from a local-only trial shape toward a directly usable
account-backed product.

Implemented in this phase:

- Flutter dependency: `supabase_flutter`.
- App startup can initialize Supabase from `--dart-define` values.
- A small `CloudAuthService` abstraction keeps the UI working when Supabase is
  not configured.
- The "我的" page shows real cloud/account state:
  - not configured;
  - configured but not signed in;
  - signed in with email.
- Email OTP login flow:
  - send OTP to email;
  - verify OTP;
  - persist session through the platform Keychain/Keystore-backed storage.
- Sign out from the "我的" page.
- Completing email OTP does not write an app profile or any local records to
  Supabase. The first app-data write happens only after the user explicitly
  chooses "立即同步到云端".
- Cloud data schema and RLS draft:
  - `docs/architecture/supabase/phase-5a-schema.sql`.
- Manual one-way sync from local SQLite to Supabase:
  - `raw_inputs`;
  - `ai_parse_results`;
  - `extracted_items`;
  - `tasks`;
  - `short_term_states`;
- `life_events`;
- `profile_items`.
- `summaries` and `summary_sources`.
- The sync path first upserts `profiles`, then upserts local records in foreign
  key order. Existing cloud rows with the same id are updated.

Not implemented yet:

- bidirectional offline sync;
- multi-device conflict resolution;
- third-party login;
- durable server-side quota or billing enforcement.

## 2. Runtime Configuration

The app intentionally does not store Supabase credentials in source code.

Run the mobile app with:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

For a debug APK:

```bash
flutter build apk --debug \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

Use the publishable client key in Flutter. Do not put the secret key or service
role key into the mobile app.

If either value is missing, the app still runs, but the "我的" page shows
"未配置云端" and login opens a configuration explanation instead of making a
network call.

The private trial deliberately does not use Supabase Flutter's default
SharedPreferences session persistence. Session and PKCE verifier values are
stored through `flutter_secure_storage`, using Android KeyStore-backed
encryption and iOS Keychain items that do not migrate to another device. The
actual Android/iOS build and restart behavior still require true-device
verification before release.

## 3. Data Ownership Boundary

Cloud records are user-owned. Every user data table has:

- `user_id`;
- `created_at`;
- `updated_at` where the row can change;
- soft status fields where records are user-visible and deleteable.

RLS rule shape:

```sql
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id)
```

This means a signed-in user can only read and mutate rows that belong to their
own Supabase auth user id.

## 4. Cloud Tables

The first cloud schema mirrors the existing local memory/action model:

- `profiles`
- `raw_inputs`
- `ai_parse_results`
- `extracted_items`
- `tasks`
- `short_term_states`
- `life_events`
- `profile_items`
- `summaries`
- `summary_sources`

`summaries` and `summary_sources` are included now because Phase 5B `/review`
will need daily review storage and source traceability.

## 5. Local SQLite Role After Phase 5A

SQLite remains the primary runtime display store for tasks, states, events, and
profile items. The first cloud sync is manual and one-way:

```text
local SQLite -> Supabase
```

The app does not yet read records back from Supabase into local SQLite, and it
does not merge edits across devices. A signed-in user can explicitly choose
"删除云端副本" to delete all remote rows owned by that account; this leaves the
local SQLite data intact. SQLite should become:

- cache for fast local display;
- migration source for existing user data;
- offline fallback for later, if needed.

Do not implement automatic two-way sync until these decisions are made:

- local record id vs cloud record id policy;
- conflict handling when two devices edit the same row;
- source deletion propagation to summaries;
- whether local raw inputs should be uploaded by default.

## 6. Local-only calendar boundary (2026-07-10)

The user chose a stricter privacy boundary for Phase 5D.1:

- explicit task start/end times;
- daily recurrence rules and generated recurrence instances;
- sedentary sessions and their reminder timing;
- schedule plans, schedule blocks, and their source links.

These data stay on the device, including when the user manually triggers the
existing one-way cloud sync. For a task carrying a local-only calendar field,
the sync service deliberately omits the legacy cloud `due_time` fields too, so
an exact schedule is not reconstructed remotely by accident.

This rule only stops future uploads. It does not delete calendar data that an
earlier build may already have uploaded. The visible, confirmed "删除云端副本"
action removes these older rows along with the user's other cloud records;
verify it against the live project before offering it beyond the private trial.

## 7. AI endpoint login boundary (2026-07-10)

Email OTP login is now also the gate for the three paid/sensitive AI actions:
`/parse`, `/review`, and `/plan`.

- Flutter attaches the current Supabase user access token only for those AI
  calls.
- The API proxy verifies that token with Supabase Auth using a publishable key.
- Missing, expired, or invalid sessions are rejected before a DeepSeek request
  is made.
- The API has an in-memory per-user burst limit (20 requests per minute per
  warm instance) plus a durable Supabase-backed daily limit (30 requests per
  UTC day). The daily quota is consumed by a narrowly scoped RPC using the
  caller's own JWT; it fails closed if the RPC cannot be reached.
- The server must be configured with `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY` before this change is deployed. Do not put a
  Supabase service-role key in Flutter or use it for token verification.

See `docs/architecture/private-trial-security-runbook-2026-07-10.md` for the
deployment and device-test order.

## 8. First Sync Verification

The first manual sync is triggered from the "我的" page through the data/sync
entry. Verification should check Supabase Table Editor after pressing sync:

- `profiles` contains the signed-in `user_id` and email.
- `raw_inputs` contains the original user input text.
- `ai_parse_results` contains the AI parse envelope.
- `extracted_items` contains the pending or confirmed AI-extracted rows.
- `tasks` contains confirmed tasks only after the user confirms a task card.

If only `raw_inputs`, `ai_parse_results`, and `extracted_items` appear, that is
expected when the user has submitted input but has not confirmed the extracted
task yet.

## 9. Suggested Next Step

Next session should choose one of two paths:

1. Add automatic sync after submit/confirm/delete actions.
2. Build Phase 5B `/review` first and store summaries in Supabase while
   formal records remain local.
3. Start a proper two-way sync design with device ids and conflict rules.

The safer next step is usually option 1, because it turns the current manual
sync into a more natural product behavior without taking on multi-device
conflict resolution yet.

## 10. Source References

- Supabase Flutter quickstart:
  https://supabase.com/docs/guides/getting-started/quickstarts/flutter
- Supabase email OTP:
  https://supabase.com/docs/reference/dart/auth-signinwithotp
- Supabase Row Level Security:
  https://supabase.com/docs/guides/database/postgres/row-level-security
