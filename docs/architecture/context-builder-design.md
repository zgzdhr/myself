# Controlled Context Builder Design

Date: 2026-06-05  
Scope: Future design only. This document does not implement database, Flutter, or API changes.

## 1. Purpose

The Context Builder is the future layer that answers:

> When the user sends an input, which memory records should be included in the AI prompt, and which records should be excluded?

It is needed because the app should not upload all personal memory to the AI model on every request. The builder should:

- Avoid uploading all memory.
- Reduce token cost and latency.
- Reduce privacy exposure.
- Avoid stale or irrelevant records affecting replies.
- Make AI suggestions explainable.
- Support memory-based replies without building a full autonomous agent.

The current `HomeSuggestionService` is already a small local version of this idea: it uses confirmed tasks, active short-term states, and confirmed profile items. This document expands that idea into a future controlled prompt-context layer.

## 2. Non-goals

This task does not design or implement:

- Vector search.
- Semantic embeddings.
- LLM reranking.
- Behavior pattern inference.
- Autonomous agents.
- Cloud sync.
- SillyTavern-style World Info, Lorebook, or roleplay memory systems.

SillyTavern's World Info and Data Bank concepts are useful only as conceptual references for activation, scope, insertion order, insertion position, and context budgeting. This app should not copy their roleplay prompt architecture and should not implement RAG or vector storage in the MVP.

References:

- [SillyTavern World Info](https://docs.sillytavern.app/usage/core-concepts/worldinfo/)
- [SillyTavern Data Bank](https://docs.sillytavern.app/usage/core-concepts/data-bank/)

## 3. Core principles

The Context Builder should follow these rules:

- Minimum necessary context: include only records that can help answer the current request.
- User-visible memory only: prefer formal records the user can view, edit, delete, or trace.
- Deleted records are excluded.
- Rejected records are excluded.
- Pending records are not truth.
- Unconfirmed profile candidates are not active truth.
- Expired short-term states are excluded from current suggestions.
- Raw inputs are not included by default.
- Summaries are optional compressed context, not truth.
- Current user input has highest priority.
- Context must be explainable: the app should be able to say which records influenced a reply.

The builder should be rule-first, not model-first:

```text
User input
→ detect broad intent
→ query only allowed tables
→ exclude unsafe/status-invalid records
→ rank and budget records
→ assemble structured context package
→ send package to parser or assistant model
```

## 4. Context sections

The builder should assemble a structured context package instead of one mixed paragraph. Each section has its own source, inclusion rule, budget, and priority.

| Section | Source table | Inclusion rule | Exclusion rule | Max count | Max length | Priority | Example content |
|---|---|---|---|---:|---:|---:|---|
| `current_user_input` | Request payload, optionally `raw_inputs` after save | Always include the exact current input. | Never exclude. | 1 | Full current input, with app-level max input length. | 100 | `我现在该干什么？` |
| `current_time` | Device/app clock | Always include local date, time, timezone. | None. | 1 | One ISO timestamp plus local date text. | 98 | `2026-06-05T09:00:00+08:00` |
| `current_intent` | Intent classifier or parser result | Include the detected broad intent and confidence. | If uncertain, mark as `unknown` instead of guessing. | 1 | 1-2 lines. | 96 | `current_suggestion`, confidence `0.82` |
| `today_tasks` | `tasks` | Confirmed tasks due today or no due date but created/edited today. | Deleted, archived, rejected, pending; completed/cancelled unless review asks for them. | 5 | 120 chars each. | 90 | `tasks:t1 联系王总, due: 今天下午` |
| `overdue_tasks` | `tasks` | Confirmed tasks with `dueTime < now` and still active. | Deleted, archived, completed/cancelled. | 5 | 120 chars each. | 92 | `tasks:t2 提交材料, overdue since 昨天` |
| `next_7_days_tasks` | `tasks` | Confirmed active tasks due within the next 7 days. | Deleted, archived; tasks already listed in overdue/today sections. | 5 | 120 chars each. | 82 | `tasks:t3 周一复查合同` |
| `active_short_term_states` | `short_term_states` | Confirmed states whose `validUntil > now`. | Deleted, rejected, pending, expired; past states unless review asks for history. | 5 | 120 chars each. | 80 | `short_term_states:s1 今天很累, validUntil: tonight` |
| `confirmed_profile_items` | `profile_items` | Confirmed profile items relevant to the intent. | Deleted, archived, pending candidates; weak or unconfirmed profile observations. | 5 | 160 chars each. | 75 | `profile_items:p1 不喜欢太频繁的提醒` |
| `recent_life_events` | `life_events` | Confirmed life events from a recent range or matching simple tags/keywords. | Deleted, archived, unrelated events; old events unless review/topic asks for them. | 5 | 180 chars each. | 60 | `life_events:e1 今天客户沟通不舒服` |
| `relevant_summaries` | Future `summaries` table from Task 10 | Active or user-edited summaries relevant to the intent, date, or topic. | Deleted, superseded, archived; `profile_candidate_summary` unless reviewing candidates. | 3 | 400 chars each. | 50 | `daily_summary: 今天主要有两个任务未完成...` |
| `pending_items_if_needed` | `extracted_items` | Only for explicit confirm/edit flows or task update disambiguation. | Rejected/deleted items; pending items must be marked as not truth. | 5 | 140 chars each. | 55 | `pending extracted_items:x1 可能是任务：联系王总` |
| `assistant_policy_notes` | Static app rules | Include rules needed for this request, such as "do not infer long-term profile". | Keep short; do not include unrelated policy text. | 5 bullets | 600 chars total. | 95 | `Do not treat one-time emotion as profile.` |

Priority means selection priority inside the builder. It does not mean the model should blindly obey lower-quality records over the current user input.

## 5. Intent-specific context rules

The MVP can start with a small set of broad intents. This does not require a full autonomous agent; it only controls which records are allowed into the prompt.

### `current_suggestion`

Example:

```text
我现在该干什么？
```

Include:

- `current_user_input`
- `current_time`
- `current_intent`
- `overdue_tasks`
- `today_tasks`
- Important `next_7_days_tasks`
- `active_short_term_states`
- Relevant `confirmed_profile_items`
- `assistant_policy_notes`

Exclude:

- Old raw inputs.
- Expired states.
- Deleted records.
- Unconfirmed profile candidates.
- Unrelated life events.

Main rule:

Current action suggestions should be based primarily on current tasks and current state. Summaries can support the reply later, but they should not override tasks or active states.

### `daily_review`

Example:

```text
帮我复盘今天。
```

Include:

- Today's tasks, including completed, active, cancelled, and overdue if they affected today.
- Today's short-term states, including states active today.
- Today's life events.
- Relevant `daily_summary` if available and active.
- Confirmed profile items only if they explain review style or reminder preference.

Exclude:

- Unrelated old records.
- Raw inputs unless the user asks for original wording.
- Rejected/deleted records.
- Unconfirmed profile candidates as truth.

### `weekly_review`

Example:

```text
帮我复盘这周。
```

Include:

- This week's tasks by status.
- This week's confirmed life events.
- This week's short-term states, including expired ones only because this is past-history review.
- Active `weekly_review_summary` if available.
- Daily summaries from the week if available and relevant.

Exclude:

- Raw inputs by default.
- Long-term pattern claims unless clearly marked as candidates.
- Deleted records.

Main rule:

Weekly review may mention repeated situations, but it must not convert them into active long-term profile.

### `task_update_resolution` (B2 implemented)

Date: 2026-06-05. Phase 3 B2.

The `task_update_resolution` intent is now implemented as
`ContextBuilder.buildTaskUpdateResolution()`. It provides active confirmed tasks
as `ContextTaskCandidate` objects for the `ExtractedItemsController` to match
against parser-supplied target titles.

Include:

- Confirmed tasks only (status = `confirmed`).
- Minimal candidate fields: `id`, `title`, `priority`, `dueTimeText`, `dueTime`.

Exclude:

- `deleted` tasks.
- `archived` tasks.
- Raw inputs, life events, profile items, summaries, short-term states.
- Task content/description beyond the candidate fields.

Implementation files:

- `apps/mobile/lib/features/context/context_builder.dart` — `ContextTaskUpdatePackage`, `ContextTaskCandidate`, `buildTaskUpdateResolution()`
- `apps/mobile/lib/features/extracted_items/extracted_items_controller.dart` — `_resolveTaskUpdateIntent` now uses `contextBuilder.buildTaskUpdateResolution()` instead of `database.getActiveTasks()`

### `task_update` (design only)

Example:

```text
把联系王总改到后天。
```

Include:

- Current input.
- Active tasks.
- Candidate matching tasks by title, due text, or simple keyword.
- Recent task-related `extracted_items` only if needed for disambiguation.

Exclude:

- Unrelated profile items.
- Unrelated life events.
- Summaries by default.
- Raw inputs unless needed to show source text for confirmation.

Main rule:

Task update context should be narrow. The model should identify which task is being changed, not reason about the user's broader life.

### `general_answer`

Example:

```text
Flutter 是什么？
```

Include:

- Current input.
- Current time only if useful.

Exclude:

- Personal memory by default.
- Tasks, states, life events, profile items, summaries.

Main rule:

General knowledge questions should not load private memory unless the user explicitly asks for personal context, such as "结合我的项目解释 Flutter".

### `life_event_reflection`

Example:

```text
今天跟客户沟通不太舒服，帮我分析一下。
```

Include:

- Current input.
- Recent relevant life events if clearly related by tag or simple keyword.
- Confirmed communication preferences if available.
- Active short-term states if they may affect the user's current energy or mood.

Exclude:

- Unrelated customer/project history.
- Unconfirmed profile candidates.
- Old raw inputs by default.

Main rule:

The assistant should not pretend to know the full customer or project background. It can say "based on what you wrote now and the few related records available".

### `memory_edit_request`

Example:

```text
把我不喜欢开会那条删掉。
```

Include:

- Candidate matching memory records from `profile_items`, `short_term_states`, `life_events`, and `tasks` depending on wording.
- Source text or source summary only if needed for user confirmation.
- Status and record type.

Exclude:

- Unrelated memories.
- Raw inputs unless source confirmation is needed.
- Rejected/deleted records unless user asks for deletion history.

Main rule:

Memory edit context should support safe selection and confirmation. It should not quietly delete ambiguous records.

### `profile_question`

Example:

```text
你觉得我是什么样的人？
```

Include:

- Confirmed `profile_items`.
- Optional active profile-related summaries.
- Candidate profile observations only if clearly separated as unconfirmed.

Exclude:

- One-time life events as personality truth.
- Short-term states as long-term traits.
- Deleted or rejected records.

Main rule:

The answer must separate:

```text
Confirmed profile:
- ...

Possible candidates, not confirmed:
- ...
```

### `unknown`

Example:

```text
你看这个咋办？
```

Include:

- Current input.
- Current time.
- Only the safest small context if the wording clearly references current tasks or memory.

Exclude:

- Broad private memory by default.

Main rule:

When intent is unclear, ask a short follow-up question or provide a low-context answer instead of loading many records.

## 6. Exclusion rules

Hard exclusion rules:

- `deleted` records are never included unless the user explicitly asks for deletion history.
- `rejected` extracted items are never included as truth.
- `pending` extracted items are not truth.
- `expired` short-term states are not included in current-suggestion context.
- `profile_candidate` is not included as active profile unless confirmed into `profile_items`.
- `raw_inputs` are not included by default.
- Sensitive records require extra caution and should be included only when user-visible and necessary.
- `general_answer` should not load personal memory by default.
- `ai_parse_results` are excluded from normal assistant context; use them only for debugging/parser analysis.
- `superseded`, `archived`, and `deleted` summaries are excluded from normal context.

Soft exclusion rules:

- If two sections contain the same fact, keep the formal record and drop the summary duplicate.
- If a record is old and not explicitly requested, drop it before dropping current tasks or states.
- If a record is ambiguous, include it only as a candidate needing confirmation.

## 7. Budgeting rules

MVP context limits should be simple and deterministic:

| Section | MVP limit |
|---|---:|
| `overdue_tasks` | Max 5 |
| `today_tasks` | Max 5 |
| `next_7_days_tasks` | Max 5 |
| `active_short_term_states` | Max 5 |
| `confirmed_profile_items` | Max 5 |
| `recent_life_events` | Max 5 |
| `relevant_summaries` | Max 3 |
| `pending_items_if_needed` | Max 5 |
| Total context package | Start with about 6,000-8,000 Chinese characters, or about 4,000-6,000 tokens after formatting |

Fallback behavior when over budget:

1. Never drop `current_user_input`.
2. Never drop the explicit intent.
3. Prefer newer records.
4. Prefer records directly relevant to the intent.
5. Prefer confirmed records over summaries.
6. Drop low-priority summaries first.
7. Drop older life events before current tasks or active states.
8. Truncate long content fields but keep record ids and titles.
9. If too many matching records remain, ask the user to choose instead of guessing.

The budget should be visible in logs during development, but logs must not expose sensitive full content by default.

## 8. Priority order

The builder should use this priority order:

1. Current user input.
2. Current explicit intent.
3. Active tasks directly related to the request.
4. Active short-term states.
5. Confirmed profile items relevant to the intent.
6. Recent life events.
7. Relevant summaries.
8. Older records only if explicitly requested.

Priority should be applied after hard exclusions. A high-priority record that is deleted is still excluded.

## 9. Suggested data/model shape

Future Dart or JSON-like structure:

```json
{
  "intent": "current_suggestion",
  "intent_confidence": 0.86,
  "current_time": "2026-06-05T09:00:00+08:00",
  "timezone": "Asia/Shanghai",
  "sections": [
    {
      "name": "current_user_input",
      "priority": 100,
      "items": [
        {
          "id": "request:current",
          "source_table": "request",
          "content": "我现在该干什么？",
          "included_reason": "current request"
        }
      ]
    },
    {
      "name": "today_tasks",
      "priority": 90,
      "items": [
        {
          "id": "tasks:t1",
          "source_table": "tasks",
          "content": "联系王总",
          "status": "confirmed",
          "due_time_text": "今天下午",
          "included_reason": "due today"
        }
      ]
    },
    {
      "name": "active_short_term_states",
      "priority": 80,
      "items": [
        {
          "id": "short_term_states:s1",
          "source_table": "short_term_states",
          "content": "今天很累",
          "status": "confirmed",
          "valid_until": "2026-06-05T23:59:59+08:00",
          "included_reason": "active state"
        }
      ]
    }
  ],
  "excluded_reason_counts": {
    "deleted": 2,
    "expired": 3,
    "pending": 1,
    "over_budget": 4
  }
}
```

Possible Dart model names for future implementation:

```text
ContextIntent
ContextPackage
ContextSection
ContextItem
ContextExclusionSummary
ContextBudget
```

The model should preserve ids and reasons because explainability depends on source traceability.

## 10. Prompt assembly

The prompt should keep context sections separate. Avoid mixing profile, task, state, and summary text into one paragraph.

Suggested assistant prompt shape:

```text
System:
You are an assistant for a local-first personal memory and action app.
Use only the provided context. Do not invent personal facts.
Do not treat candidates or summaries as confirmed profile.
If context is insufficient, say what is missing.

Current user input:
{{current_user_input}}

Current time:
{{current_time}}

Detected intent:
{{current_intent}}

Current tasks:
{{today_tasks}}
{{overdue_tasks}}
{{next_7_days_tasks}}

Active short-term states:
{{active_short_term_states}}

Confirmed profile items:
{{confirmed_profile_items}}

Recent life events:
{{recent_life_events}}

Relevant summaries:
{{relevant_summaries}}

Policy notes:
{{assistant_policy_notes}}
```

Important prompt rules:

- The model may use summaries as supporting context only.
- Confirmed `profile_items` outrank summaries.
- Current tasks and active states outrank older records.
- The model should mention uncertainty when the selected context is thin.
- The model should avoid saying "I know you always..." unless there is a confirmed profile item.

## 11. Explainability

Every memory-based suggestion should be explainable in user-visible language.

Good explanation:

```text
我建议你先处理“联系王总”，因为它是今天的已确认任务；同时你今天记录过“有点累”，所以我建议用低阻力方式先发一条简短消息。
```

Bad explanation:

```text
根据你的长期模式，你现在应该联系王总。
```

Why the bad one is wrong:

- It claims a long-term pattern.
- It hides source records.
- It may overstate what the app knows.

The builder should carry `included_reason` fields so the UI can later show:

```text
Used:
- tasks:t1 because due today
- short_term_states:s1 because still active
- profile_items:p1 because confirmed reminder preference
```

## 12. Future upgrade path

Do not implement these in MVP, but leave a clean path:

1. Simple keyword/tag search.
2. Summary-based context from `docs/architecture/summary-system-design.md`.
3. User-controlled topic filters.
4. Vector search.
5. LLM rerank.

Upgrade boundaries:

- Keyword/tag search can still be deterministic and local-first.
- Summaries must remain visible, editable, deletable compressed context.
- Vector search should wait until simple rules fail in real use.
- LLM rerank should never get the full private database by default.

## 13. MVP recommendation

Do not implement a full Context Builder immediately if the current app still needs stabilization.

When implementation starts, begin with the current `HomeSuggestionService` pattern:

```text
current_suggestion
→ current input and time
→ overdue/today/next-7-day tasks
→ active short-term states
→ confirmed profile items
→ source reasons
```

Then add one intent at a time:

1. `general_answer`, because it should deliberately include no private memory by default.
2. `task_update`, because it benefits from narrow active-task matching.
3. `daily_review`, because it can use existing records without vector search.
4. `life_event_reflection`, because it needs more careful relevance rules.
5. `profile_question`, because it has the highest risk of turning candidates into false identity claims.

Current B-state implementation:

```text
ContextBuilder.buildCurrentSuggestion()
→ returns ContextPackage for current_suggestion
→ used by HomeSuggestionService

ContextBuilder.buildTaskUpdateResolution()
→ returns ContextTaskUpdatePackage for task_update_resolution
→ used by ExtractedItemsController._resolveTaskUpdateIntent
→ provides active confirmed task candidates for task update matching
```

The smallest useful first implementation is:

```text
ContextBuilder.build(intent: current_suggestion)
→ returns a structured context package
→ HomeSuggestionService or future assistant prompt uses it
→ UI can explain which records were used
```

The most important boundary:

> The Context Builder selects user-visible evidence; it does not create new truth about the user.
