# Phase 3 Verification

Date: 2026-06-08
Scope: Phase 3 real-use stabilization and Android real API trial

## Summary

Phase 3 has reached real-device trial readiness: the mobile app can run on an
Android phone, call the local API proxy, receive real DeepSeek parse results,
create extracted items, and write confirmed records to local SQLite memory.

The phase should not be treated as fully polished. The first Samsung phone
trial found important product trust issues that should drive the next phase:
time semantics, task update matching, today filtering, pending confirmation
persistence, and date-based test controls.

Detailed trial feedback is recorded in:

- `docs/architecture/phase-3-real-trial-feedback.md`

## Completed Phase 3 Capabilities

- Real DeepSeek parser prompt, schema, sample set, and smoke checks cover the
  six MVP item types.
- Mobile parser client can call the API proxy with UTF-8 Chinese input.
- Extracted item confirmation, edit, reject, auto-save, and undo/delete flows
  exist for MVP records.
- `task_update_resolution` ContextBuilder intent exists for active task
  matching.
- Home suggestion uses current task/state/profile context and rule-based
  explanations.
- Memory management pages let the user inspect and delete saved tasks, states,
  life events, and profile items.
- Unified project verification script exists at `scripts/check-all.sh`.
- Android real API debug APK was built for Samsung phone trial.

## Latest Manual Trial

Environment:

- Device: Samsung Android phone.
- APK: Phase 3 real API debug build.
- API proxy: local Mac API proxy on port 8787.
- AI provider: DeepSeek through the API proxy.

Verified:

- APK installs and can be used for real trial.
- API proxy `/health` returned `{"ok":true}`.
- Real `/parse` request for `明天上午联系王总，我今天有点累。` returned
  `task_create` plus `short_term_state`.

## Known Issues From Real Trial

Accepted as next-phase backlog, not fixed in this verification document:

- `晚上` / `今晚` should usually resolve to today's evening when no other date
  is present.
- `task_update` cancellation is wording-sensitive: `下午开会的事情取消了`
  failed while `今下午不用去开会了` succeeded.
- `今天好累，健身不想去了` should become a task-update confirmation or a
  goal-aware suggestion, not be ignored.
- Tomorrow tasks can appear in today's action list.
- Pending confirmation cards can disappear after a new parse request.
- Date and time editing is too manual for future reminder work.
- Trial builds need a date switcher to test expiration and today filtering.
- Home suggestion explanations need clearer grouping and expandable layout.
- Memory delete actions need confirmation and later batch delete.

## Verification Status

Automated verification last fully passed in Phase 3 E2:

```bash
./scripts/check-all.sh
```

Recorded result:

- `flutter analyze`: pass.
- `flutter test`: pass, 105 tests.
- `npm run typecheck`: pass.
- `npm test`: pass, 53 tests.

This document records manual real-device feedback and does not introduce code
changes that require rerunning automated tests.

## Phase 3 Exit Decision

Phase 3 can close as a real-trial stabilization phase if the project accepts
that the issues above become next-phase priorities.

Recommended next phase order:

1. Preserve pending confirmation batches.
2. Fix today/tomorrow and same-day time semantics.
3. Tighten task update matching for cancel / do not want to do / not going.
4. Add debug date switching for real trial builds.
5. Improve task deadline editing with date/time picker.
6. Redesign home suggestion and today action cards after data behavior is
   stable.
