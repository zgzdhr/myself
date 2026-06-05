# Task Update Resolution Rules

> Last updated: 2026-06-05

This document defines how `task_update` items are resolved before they are
applied to existing tasks. It is intentionally narrow: it only covers MVP task
updates and does not introduce a full agent, vector search, automatic profile
evolution, or new item types.

## Goal

`task_update` is the bridge between a natural-language update and an existing
task record.

The app must answer one question before applying any update:

```text
Which existing active task is the user trying to update?
```

If that answer is not clear, the app should ask the user to choose or explain
that no matching task was found. It should not guess.

## Current Implementation

Current task update logic lives in:

- `apps/mobile/lib/features/extracted_items/extracted_items_controller.dart`
- `apps/mobile/lib/domain/extracted_item.dart`
- `apps/mobile/test/features/extracted_items/confirmation_flow_test.dart`

The parser can create a `TaskUpdateIntent` with:

- `action`: `complete`, `cancel`, `delay`, or `edit`
- `targetTaskTitle`: structured target title from the parser
- `targetText`: fallback target text from the parser
- `dueTimeText`: natural-language due time for delay
- `dueTime`: parsed due time for delay
- `candidates`: task candidates found locally
- `resolution`: `ready`, `needsSelection`, or `noMatch`

The controller currently resolves against `database.getActiveTasks()`, which
only returns tasks whose record `status` is `confirmed`. This means `deleted`
and `archived` tasks are excluded from matching.

Matching currently uses this order:

1. Build a target query from `targetTaskTitle`, then `targetText`.
2. Normalize by trimming, removing spaces, and lowercasing.
3. If the normalized query is empty, return `noMatch`.
4. Prefer exact title matches.
5. If there is no exact match, use title-contains-query matches.
6. Resolve by candidate count:
   - `0` candidates -> `noMatch`
   - `1` candidate -> `ready`
   - `2+` candidates -> `needsSelection`

## Resolution States

### `ready`

Use `ready` only when there is exactly one safe candidate.

Current MVP condition:

- The parser supplied a non-empty `targetTaskTitle` or `targetText`.
- Exactly one active task matches by exact title, or exactly one active task
  matches by the current contains rule.

Expected behavior:

- The UI may show a confirmation card such as "will mark as completed" or
  "will delay to tomorrow morning".
- Applying the update can directly use the single candidate.

Important boundary:

- If one exact match exists and other looser contains matches also exist, the
  current code chooses the exact match. This is acceptable for MVP, but future
  matching should still expose enough explanation for the user to understand
  why that task was selected.

### `needsSelection`

Use `needsSelection` when the update intent is understandable, but more than
one active task could be the target.

Current MVP condition:

- The parser supplied a non-empty target.
- Matching finds two or more candidates.

Examples:

- Existing tasks: `联系王总-上海`, `联系王总-北京`
- User says: `把联系王总改到后天`
- Resolution: `needsSelection`

Expected behavior:

- Do not apply the update immediately.
- Show candidates and ask the user which task should be updated.
- Applying is allowed only after the user selects a candidate id from the
  candidate list.

### `noMatch`

Use `noMatch` when there is no safe task target.

Current MVP condition:

- `targetTaskTitle` and `targetText` are both empty after normalization, or
- No active task matches the supplied target.

Examples:

- User says: `完成了`
- User says: `那个事处理好了`
- User says: `取消一下`
- User says: `联系李总完成了`, but the only active task is `联系张总`

Expected behavior:

- Do not update any task.
- Keep the extracted item pending, so the user can review or discard it.
- Show a clear message that no corresponding task was found.

## Ambiguous References

Generic references are not safe targets by themselves.

Examples:

- `那个事`
- `这个任务`
- `刚才那个`
- `之前那个`
- `它`

MVP rule:

- If the parser cannot extract a concrete target title or target text from the
  same user input, resolve as `noMatch`.
- Do not use raw input history, life events, profile items, summaries, or
  inferred personal context to guess the target.
- If a generic phrase appears together with a concrete title, match only the
  concrete part. For example, `那个客户资料不用做了` can target `客户资料` if the
  parser extracts `客户资料` as `targetText`.

## Similar Titles

When multiple task titles are similar, the system must prefer user control over
silent guessing.

Rules:

- One exact match can be `ready`.
- Multiple exact matches must be `needsSelection`.
- No exact match plus multiple partial matches must be `needsSelection`.
- A partial match should never silently pick the first candidate when more than
  one candidate exists.
- Candidate display should include enough task metadata for the user to choose,
  such as title and due time text.

## Action Rules

### `complete`

Current MVP behavior:

- `complete` calls `markTaskArchived`.
- The task record `status` becomes `archived`.
- The extracted `task_update` item becomes `confirmed` after the update is
  applied.

MVP boundary:

- `archived` currently means "completed task" for task updates.
- This is a temporary schema shortcut.

### `cancel`

Current MVP behavior:

- `cancel` calls `markTaskDeleted`.
- The task record `status` becomes `deleted`.
- The extracted `task_update` item becomes `confirmed` after the update is
  applied.

MVP boundary:

- `deleted` currently means "cancelled task" for task updates.
- This overlaps with real deletion and undo behavior, so it should not be
  treated as the final model.

### `delay`

Current MVP behavior:

- `delay` updates `dueTimeText` and `dueTime` on the selected task.
- If both values are missing, the current code can still apply and effectively
  clear the task due time.

Required B-stage rule:

- Delay should require a new time signal.
- If `dueTimeText` and `dueTime` are both missing, do not apply immediately.
- Prefer `needsSelection` when there are candidates but the update needs user
  clarification; use `noMatch` when there is no safe target.

### `edit`

Current MVP behavior:

- `edit` updates the selected task title using `item.content`, then
  `item.title`, then the existing candidate title as fallback.

Required B-stage rule:

- Edit should have a concrete selected target and a concrete replacement value.
- If either side is missing, do not silently overwrite.

## Cancel vs Delete

Product meaning:

- `cancel`: the user says the task no longer needs to be done.
- `delete`: the user removes a record from memory or undoes an auto-saved item.

Current schema limitation:

- Both cancellation and deletion currently use record `status = deleted` in
  the `tasks` table.

Risk:

- The app cannot later distinguish "I cancelled this task" from "I deleted this
  record and do not want it used".

MVP decision:

- Keep the current schema for B1.
- Document the risk clearly.
- Avoid building analytics, review, or memory behavior that depends on knowing
  whether a deleted task was cancelled or removed.

## Recommended Future Schema Direction

The current `status` field is doing two jobs:

- Record lifecycle: `confirmed`, `deleted`, `archived`, etc.
- Task business state: active, completed, cancelled.

Future schema should split these concerns:

```text
tasks.status       -> record lifecycle, for visibility and deletion
tasks.task_status  -> task business state
```

Recommended `task_status` values:

- `active`
- `completed`
- `cancelled`

Future mapping:

- New task -> `status = confirmed`, `task_status = active`
- Complete -> `status = confirmed`, `task_status = completed`
- Cancel -> `status = confirmed`, `task_status = cancelled`
- Delete memory record -> `status = deleted`, keep `task_status` unchanged or
  clear it according to the deletion policy

This keeps user memory control separate from task workflow meaning.

## B2/B3 Implementation Guardrails

When implementation continues after this document:

- `task_update` context should come from `ContextBuilder`, not from scattered
  controller queries.
- Candidate context should only include active confirmed tasks.
- Candidate context should not include raw input text, life events, profile
  items, summaries, or private free-form memory.
- Candidate fields should be minimal: `id`, `title`, `priority`,
  `dueTimeText`, and `dueTime`.
- Debug JSON should count exclusion reasons but avoid sensitive text.
- Generic references like `那个事` should not be guessed into a task target.
- `delay` should not apply without a new time.
- `deleted` and `archived` tasks should never participate in matching.
