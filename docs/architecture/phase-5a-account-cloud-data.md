# Phase 5A Account and Cloud Data

Date: 2026-06-18

Status: first implementation complete. This document records the account and
cloud-data boundary that new sessions should follow.

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
  - persist session through Supabase Flutter's built-in local storage.
- Sign out from the "我的" page.
- Cloud data schema and RLS draft:
  - `docs/architecture/supabase/phase-5a-schema.sql`.

Not implemented yet:

- migrating existing local SQLite records into Supabase;
- bidirectional offline sync;
- multi-device conflict resolution;
- third-party login;
- deleting real cloud account data from the app;
- server-side DeepSeek proxy authentication.

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

SQLite remains the current runtime data store for tasks, states, events, and
profile items. After Supabase login is stable, SQLite should become:

- cache for fast local display;
- migration source for existing user data;
- offline fallback for later, if needed.

Do not implement automatic two-way sync until these decisions are made:

- local record id vs cloud record id policy;
- conflict handling when two devices edit the same row;
- source deletion propagation to summaries;
- whether local raw inputs should be uploaded by default.

## 6. Suggested Next Step

Next session should choose one of two paths:

1. Build a one-way migration/upload tool from local SQLite to Supabase for
   signed-in users.
2. Build Phase 5B `/review` first and store only summaries in Supabase while
   formal records remain local.

The safer path is usually option 2, because review storage is new data and does
not require migrating existing local records.

## 7. Source References

- Supabase Flutter quickstart:
  https://supabase.com/docs/guides/getting-started/quickstarts/flutter
- Supabase email OTP:
  https://supabase.com/docs/reference/dart/auth-signinwithotp
- Supabase Row Level Security:
  https://supabase.com/docs/guides/database/postgres/row-level-security
