# Current Verification

## Latest Verification: Phase 5A Manual Cloud Sync

Date: 2026-06-22
Scope: Supabase table privileges, manual one-way local SQLite to Supabase sync,
and real AI parser mode on Android emulator

### Summary

- Result: Pass.
- Supabase `authenticated` role now has `select`, `insert`, and `update`
  privileges for the user-owned cloud tables used by first sync:
  - `profiles`
  - `raw_inputs`
  - `ai_parse_results`
  - `extracted_items`
  - `tasks`
  - `short_term_states`
  - `life_events`
  - `profile_items`
- RLS remains enabled and still limits access by `auth.uid() = user_id`.
- Mobile added `CloudSyncService`, which uploads local SQLite records to
  Supabase in foreign-key order.
- The current sync is manual and one-way:

```text
local SQLite -> Supabase
```

- The app does not yet pull cloud records back into SQLite and does not handle
  multi-device conflict resolution.
- Android emulator was relaunched in real parser mode:

```bash
flutter run -d emulator-5554 \
  --dart-define=PARSER_MODE=http \
  --dart-define=PARSER_BASE_URL=http://10.0.2.2:8787 \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

### Commands Run

```bash
cd apps/mobile
flutter analyze
flutter test test/features/account/cloud_auth_service_test.dart
flutter test

cd apps/api
npm run dev

curl -sS http://127.0.0.1:8787/health
curl -sS -X POST http://127.0.0.1:8787/parse \
  -H 'Content-Type: application/json' \
  --data '{"text":"明天上午提醒我联系王总","timezone":"Asia/Shanghai","current_time_iso":"2026-06-22T17:55:00+08:00"}'
```

### Results

- `flutter analyze`: Pass, no issues found.
- Account service test: Pass.
- Full mobile test suite: Pass, 145 tests passed.
- API proxy health: Pass, returned `{"ok":true}`.
- Real `/parse` request: Pass, returned `task_create` for "联系王总".
- Manual Supabase sync was user-verified in Table Editor: `profiles` and local
  business records appeared after pressing sync.

### Notes

- If a submitted input has not yet been confirmed, cloud sync should populate
  `raw_inputs`, `ai_parse_results`, and `extracted_items`, but not necessarily
  `tasks`.
- `tasks` receives a row only after a task card is confirmed locally.
- Completed or deleted tasks are soft-updated in cloud by status fields rather
  than physically removed in the first sync version.
- Recommended next implementation remains Phase 5B `/review`; optional small
  enhancement is automatic sync after submit / confirm / delete.

## Latest Verification: Phase 5A Account and Cloud Data

Date: 2026-06-18
Scope: Supabase Flutter dependency, environment-based cloud initialization,
email OTP auth service, profile/settings account state, Supabase schema/RLS
draft, and account tests

### Summary

- Result: Pass.
- Mobile app now depends on `supabase_flutter`.
- Startup initializes Supabase only when both `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY` are passed through `--dart-define`.
- `CloudAuthService` provides a small account abstraction with a disabled
  fallback for unconfigured debug/test builds.
- The "我的" page now shows real cloud/account state:
  - `未配置云端` when Supabase is missing;
  - configured but not signed in;
  - signed in email when a Supabase session exists.
- Email OTP login and sign-out are wired through Supabase when configured.
- Supabase schema/RLS draft added at
  `docs/architecture/supabase/phase-5a-schema.sql`.
- Phase 5A boundary doc added at
  `docs/architecture/phase-5a-account-cloud-data.md`.

### Commands Run

```bash
cd apps/mobile
flutter pub get
flutter analyze --no-pub
flutter test test/features/account/cloud_auth_service_test.dart test/widget_test.dart
flutter test
flutter build apk --debug
```

### Results

- `flutter pub get`: Pass, `supabase_flutter` resolved to `2.15.0`.
- `flutter analyze --no-pub`: Pass, no issues found.
- Account + widget tests: Pass, 4 tests passed.
- Full mobile test suite: Pass, 145 tests passed.
- `flutter build apk --debug`: Pass, built
  `build/app/outputs/flutter-apk/app-debug.apk`.

### Notes

- No Supabase secret or service role key is stored in the repo.
- Real login requires runtime values:
  `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.
- Existing local SQLite records are not automatically uploaded yet.
- Recommended next implementation is Phase 5B `/review`; optionally store new
  summaries in Supabase before attempting historical SQLite migration.
- First Android build after adding Supabase installed Android SDK Platform 34
  and printed Kotlin Gradle Plugin / deprecated API warnings from transitive
  plugins. Build completed successfully.

## Previous Verification: Phase 5C Settings/Profile Shell

Date: 2026-06-18
Scope: Bottom navigation shell, tasks as a first-level tab, review entry
placeholder, and profile/settings page structure

### Summary

- Result: Pass.
- App shell now has four bottom navigation destinations: 首页, 任务, 复盘, 我的.
- Tasks are now a first-level navigation entry instead of only being reachable
  through memory management.
- Review has a first visible entry point for future `/review` daily summaries.
- Profile/settings has a stable first version covering account, sync,
  reminders, review settings, AI/memory, privacy/data, and app/help sections.
- The settings page intentionally uses placeholder actions for features not yet
  connected, such as email login, cloud sync, data export, and real review
  generation.

### Commands Run

```bash
cd apps/mobile
flutter analyze --no-pub
flutter test test/widget_test.dart test/features/memory/memory_management_test.dart
flutter test
```

### Results

- `flutter analyze --no-pub`: Pass, no issues found.
- Targeted widget and memory tests: Pass, 28 tests passed.
- Full mobile test suite: Pass, 144 tests passed.

### Notes

- Full mobile tests still print an existing Drift debug warning about multiple
  `AppDatabase` instances in tests. The warning did not fail the suite and was
  not introduced by this settings/profile change.
- Two old untracked root files remain outside this change:
  `2026-06-07-phase3_d0.md` and `2026-06-08-phase3-upgrade.md`.

## Previous Verification: Phase 4B Time Semantics and Today Actions

Date: 2026-06-08
Scope: Time reference contract, optional location context contract, same-day
implicit time semantics, today/future task filtering, task time display, and
task date/time editing

### Summary

- Result: Pass with one known API privacy test gap.
- Phase 4B fixes were implemented, committed, and pushed in
  `f62bba1 feat: complete phase 4B time fixes`.
- Mobile parser requests now include `current_time_iso`, so API / DeepSeek can
  resolve "今天", "明天", and "今晚" against the user's current local time.
- API schema and prompt now support optional `location_context`; the mobile app
  does not upload location by default, and the prompt says not to guess location
  when it is not provided.
- ContextBuilder now separates overdue, today, next-seven-days, and unscheduled
  tasks, so tomorrow and unscheduled tasks do not appear in today's actions.
- Task due-time display now shows concrete date/time plus original time text
  when available, "时间待明确" for vague original time, and "未设时间" when no
  time exists.
- Task editing now supports date picker, time picker, and clearing due time.

### Commands Run

```bash
cd apps/mobile
flutter analyze
flutter test

cd apps/api
npm run typecheck
node --test --import tsx test/deepseekParser.test.ts test/parseResultSchema.test.ts test/parserPrompt.test.ts
```

### Results

- `flutter analyze`: Pass, no issues found.
- `flutter test`: Pass, 118 tests passed.
- `npm run typecheck`: Pass.
- API parser/schema/prompt tests: Pass, 28 tests passed.

### Known Gap

- `node --test --import tsx test/privacyLogging.test.ts` hangs when run
  individually in the current environment. That test is responsible for
  checking API error logs include request metadata but not raw user text. It
  should be repaired separately by investigating the test HTTP server / fetch
  lifecycle.
- The Phase 4B commit only updated this test's request payload with
  `current_time_iso`; it was not counted as a passing verification target.

### Notes

- Existing unrelated documentation, Android manifest, and phase planning draft
  changes were not part of the Phase 4B code commit.
- Next active work is Phase 4C: real Chinese `task_update` semantics and target
  matching.

## Previous Verification: Phase 4A Trust Fixes

Date: 2026-06-08
Scope: Pending confirmation persistence, delete confirmation dialogs, and debug date switcher

### Summary

- Result: Pass.
- Phase 4A trust fixes were implemented and committed in
  `c389778 feat: complete phase 4A trust fixes`.
- Input screen now preserves recent pending extracted-item batches instead of
  letting earlier unconfirmed content disappear after a new parse request.
- Memory delete actions now ask for confirmation before deleting tasks,
  short-term states, life events, and profile items.
- Debug builds now include a date switcher so date-based home suggestion and
  short-term-state expiration behavior can be tested without waiting for the
  real next day.

### Commands Run

```bash
cd apps/mobile
flutter analyze
flutter test
```

### Results

- `flutter analyze`: Pass, no issues found.
- `flutter test`: Pass, 108 tests passed.

### Notes

- This verification focused on mobile because Phase 4A changed Flutter UI,
  controller, and widget tests only.
- Existing unrelated README, Android manifest, and phase planning draft changes
  were not part of the Phase 4A commit.
- Superseded by Phase 4B verification above.

## Latest Verification: Phase 3 Real Trial Feedback

Date: 2026-06-08
Scope: Samsung Android real API debug APK trial and Phase 3 feedback capture

### Summary

- Result: Trial complete with known issues.
- Android debug APK was built for real API testing against the local API proxy.
- API proxy health check passed on both localhost and LAN address.
- Real DeepSeek parse request returned valid `task_create` plus
  `short_term_state` for a Chinese sample.
- Detailed feedback is recorded in
  `docs/architecture/phase-3-real-trial-feedback.md`.
- Phase 3 verification summary is recorded in
  `docs/architecture/phase-3-verification.md`.

### Manual Checks

```bash
curl http://127.0.0.1:8787/health
curl http://192.168.0.103:8787/health
curl -X POST http://127.0.0.1:8787/parse \
  -H 'Content-Type: application/json' \
  -d '{"text":"明天上午联系王总，我今天有点累。","timezone":"Asia/Shanghai"}'
```

### Results

- `/health`: Pass, returned `{"ok":true}`.
- `/parse`: Pass, returned `task_create` and `short_term_state`.
- Real-trial feedback found next-phase issues in time semantics, task update
  matching, today filtering, pending confirmation persistence, date testing,
  home suggestion layout, and memory deletion safety.

### Notes

- The Android network manifest change used for local real-device testing is a
  debug/trial concern and should be handled separately from documentation-only
  verification commits.
- Latest full automated verification remains Phase 3 E2 below.

## Latest Verification: Phase 3 E2

Date: 2026-06-08
Scope: `sqlite3_flutter_libs` dependency risk review and cleanup

### Summary

- Result: Pass.
- `flutter pub outdated` showed direct dependencies are up-to-date.
- `sqlite3_flutter_libs 0.6.0+eol` was removed from direct mobile dependencies.
- `sqlite3` remains resolved at `3.3.2`, which provides the current Flutter native bundling path used by Drift.
- No business behavior changed.

### Commands Run

```bash
cd apps/mobile
flutter pub outdated
flutter pub get

cd ../..
./scripts/check-all.sh
```

### Results

- `flutter pub outdated`: Pass. Direct dependencies all up-to-date.
- `flutter pub get`: Pass. Removed `sqlite3_flutter_libs 0.6.0+eol`; changed 1 dependency.
- `./scripts/check-all.sh`: Pass.
- `flutter analyze`: Pass, no issues found.
- `flutter test`: Pass, 105 tests passed.
- `npm run typecheck`: Pass.
- `npm test`: Pass, 53 tests passed.

### Notes

- Commands that invoke Flutter or local API tests required permission mode because the sandbox blocks Flutter SDK cache writes and local server/fetch behavior.
- Flutter tests still emit the existing Drift multiple-database debug warning in one test path; tests pass and this was not introduced by E2.

## Latest Verification: Phase 3 E1

Date: 2026-06-08
Scope: Unified project check script for mobile and API verification

### Summary

- Result: Pass.
- New script: `scripts/check-all.sh`.
- README now documents the one-command verification entry point.
- The script runs mobile static checks, mobile tests, API typecheck, and API tests.
- No business behavior changed.

### Command Run

```bash
./scripts/check-all.sh
```

### Results

- `flutter analyze`: Pass, no issues found.
- `flutter test`: Pass, 105 tests passed.
- `npm run typecheck`: Pass.
- `npm test`: Pass, 53 tests passed.

### Notes

- The first sandboxed run stopped at Flutter SDK cache writes.
- The official E1 verification used permission mode because the script needs Flutter SDK cache writes and the API localhost privacy test starts a local server.
- Flutter tests still emit the existing Drift multiple-database debug warning in one test path; tests pass and this was not introduced by E1.

## Latest Verification: Phase 3 D2

Date: 2026-06-08
Scope: Rule-based `memory_explanation` design and ContextBuilder explanation metadata

### Summary

- Result: Pass.
- Mobile static verification: `flutter analyze` passed.
- Mobile automated verification: `flutter test` passed.
- API static verification: `npm run typecheck` passed.
- API automated verification: `npm test` passed.
- New design document: `docs/architecture/memory-explanation-design.md`.
- New ContextBuilder output: `ContextPackage.memoryExplanations`.
- Debug output remains count-only and does not include raw input, source text, task titles, short-term state content, or profile content.

### Commands Run

```bash
cd apps/mobile
flutter analyze
flutter test

cd ../api
npm run typecheck
npm test
```

### Results

- `flutter analyze`: Pass, no issues found.
- `flutter test`: Pass, 105 tests passed.
- `npm run typecheck`: Pass.
- `npm test`: Pass, 53 tests passed.

### Notes

- `flutter analyze`, `flutter test`, and the API localhost privacy test required permission mode because the sandbox blocks Flutter SDK cache writes and local server/fetch behavior.
- Earlier sandboxed API test attempts were cancelled after hanging on `test/privacyLogging.test.ts`; the same full API suite passed in permission mode.
- Historical note: D2 is complete. This old next-step note has been superseded
  by Phase 4 planning; current active work is Phase 4C.

## Latest Verification: Phase 3 D0

Date: 2026-06-07
Scope: Chinese semantic classification calibration for parser prompt, sample set, smoke checks, and project docs

### Summary

- Result: Pass.
- API static verification: `npm run typecheck` passed.
- API automated verification: `npm test` passed.
- Real DeepSeek smoke: 44 samples checked, 44 pass, 0 need review, 0 type mismatch, 0 schema error.
- New rules document: `docs/architecture/chinese-semantic-classification-rules.md`.
- Updated parser assets: `parserPrompt.ts`, `parserSampleSet.ts`, `smokeParseSamples.ts`.
- Updated project memory: `AGENTS.md`, `2026-06-05-phase3_副本.md`, DeepSeek smoke docs.
- Mobile Flutter tests were not rerun because D0 did not change mobile code.

### Commands Run

```bash
cd apps/api
npm run typecheck
npm test
API_BASE_URL=http://127.0.0.1:8791 npm run smoke:parse
```

### Results

- `npm run typecheck`: Pass.
- `npm test`: Pass, 53 tests passed.
- `npm run smoke:parse`: Pass, 44 samples checked.

### D0 Coverage

- Future social or entertainment arrangements are parsed as `task_create`, not `life_event`.
- Mixed future plan plus current feeling can produce `task_create` plus `short_term_state`.
- Past events that create future action can produce `life_event` plus `task_create`.
- "记得" / "remember" is separated into reminder intent versus past-memory expression by semantic meaning.
- Vague time phrases such as "过会儿", "一会儿", "待会儿", "回头", "有空", and "等我到酒店后" must preserve original time text instead of fabricating ISO dates.
- Single `life_event` evidence does not automatically become `profile_candidate`.

### Notes

- Real smoke used a freshly started API proxy on `API_PORT=8791` to avoid reading an older long-running dev process.
- Historical note: D0 is complete. The old D1 next-step note has been
  superseded by Phase 4 planning; current active work is Phase 4C.

## Previous Verification: Task 10/11 ContextBuilder

Date: 2026-06-05 19:31 CST  
Scope: Task 10/11 docs and first minimal `current_suggestion` ContextBuilder

### Summary

- Result: Pass.
- Mobile static verification: `flutter analyze` passed.
- Mobile automated verification: `flutter test` passed.
- API static verification: not rerun in this task.
- API automated verification: not rerun in this task.
- New docs added: `summary-system-design.md` and `context-builder-design.md`.
- New feature added: minimal Flutter ContextBuilder for `current_suggestion`.
- Unresolved blocking problems: none in the automated verification layer.

### Commands Run

#### apps/mobile

```bash
cd apps/mobile
flutter analyze
flutter test
```

#### apps/api

```bash
cd apps/api
npm run typecheck
npm test
```

API commands above were part of the earlier full verification record. The latest
Task 10/11 + ContextBuilder implementation only changed Flutter/docs files, so
the latest rerun focused on `apps/mobile`.

### Results

#### Mobile

- Command: `flutter analyze`
- Result: Pass
- Notes: No issues found.

- Command: `flutter test`
- Result: Pass
- Notes: 66 tests passed. Coverage includes parser contract, local database, extracted item confirmation flow, ContextBuilder, home suggestion service, memory management, privacy failure handling, and widget shell rendering.

#### API

- Command: `npm run typecheck`
- Result: Not rerun in the latest ContextBuilder task.
- Notes: Last recorded full verification passed.

- Command: `npm test`
- Result: Not rerun in the latest ContextBuilder task.
- Notes: Last recorded full verification passed.

### Latest ContextBuilder Coverage

- `apps/mobile/lib/features/context/context_builder.dart` implements only `current_suggestion`.
- `apps/mobile/lib/features/home/home_suggestion_service.dart` now reuses ContextBuilder for home suggestion context.
- `apps/mobile/test/features/context/context_builder_test.dart` verifies:
  - deleted records are excluded.
  - expired short-term states are excluded.
  - confirmed profile items are included.
  - pending extracted items are not treated as truth.
  - debug output includes excluded reason counts without raw text.
  - current suggestion context matches existing home suggestion behavior.
  - intent detection is rule-based and only recognizes current suggestion.

### Notes

- During an earlier verification attempt, `flutter test` was started in parallel with `flutter analyze` and hit the Flutter startup lock. Later test runs were executed sequentially.
- Android/iOS simulator smoke and real DeepSeek smoke remain documented separately in `mobile-smoke-test.md` and `phase-2-ai-parse-smoke.md`.
