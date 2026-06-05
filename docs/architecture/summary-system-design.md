# Small Summary System Design

Date: 2026-06-05  
Scope: Future design only. This document does not implement database, Flutter, or API changes.

## 1. Purpose

The summary system is a future lightweight layer for compressing useful memory and action records without turning the app into an autonomous agent or a roleplay chat memory system.

Summaries are needed to:

- Reduce context size before sending data to an AI model.
- Avoid sending all raw history to the model on every request.
- Support daily and weekly review flows.
- Support future memory-based replies with a compact, user-readable context.
- Provide compressed context for a future Context Builder.
- Preserve user control over what the app remembers, because every summary should be visible, editable, deletable, and traceable to source records.

The core product question remains:

> Does this information have future value for the user? If yes, where should it be stored, for how long, and when should it be brought back?

## 2. Non-goals

This task does not design or implement:

- Vector search.
- Behavior pattern inference.
- Automatic long-term profile evolution.
- Autonomous agents.
- Cloud sync.
- Complex CRM or project review workflows.
- Medical, legal, or financial conclusions.
- A SillyTavern-style roleplay memory system.

SillyTavern's Summarize extension is useful only as a conceptual reference for user-visible current summaries, rollback, pause controls, and prompt injection boundaries. This app should adapt those ideas to personal memory/action records, not copy a chat-story architecture.

Reference: [SillyTavern Summarize documentation](https://docs.sillytavern.app/extensions/summarize/)

## 3. Summary types

| Summary type | Purpose | Source records | Default time range | Can affect current suggestions? | User confirmation needed? | Can become long-term profile? |
|---|---|---|---|---|---|---|
| `recent_input_summary` | Compress the latest user inputs and parser outcomes so future replies do not need all raw text. | `raw_inputs`, confirmed or auto-saved `extracted_items`, related formal records. | Last 5-20 inputs, or since the last recent summary. | Later, yes, but only as weak context. It must not override current tasks or active states. | Not required to generate, but must be visible and editable. | No. |
| `daily_summary` | Help the user review what happened today: tasks, states, useful events, and unresolved items. | Today's `tasks`, active or same-day `short_term_states`, same-day `life_events`, confirmed `profile_items` only as context. | Local calendar day. | Later, yes, for daily review and light current suggestions. | Not required to generate, but user must be able to edit/delete it. | No. |
| `weekly_review_summary` | Support weekly reflection without scanning every record manually. | Week's tasks, completed/cancelled/overdue task status, short-term states, life events, daily summaries. | Current or previous local calendar week. | Usually no for immediate suggestions; yes for explicit weekly review. | Not required to generate, but user must be able to edit/delete it. | No. |
| `topic_summary` | Compress records around a user-visible topic, such as "client communication", "sleep", or "cooking notes". | Tagged `life_events`, related tasks, short-term states, and user-selected records. | User-selected range; default last 30-90 days. | Only when the current request asks about that topic. | User should confirm the topic and source range before generation. | No. It may produce candidates, but not active profile. |
| `profile_candidate_summary` | Collect possible long-term profile candidates from multiple records for user review. | Repeated user-confirmed records, edited summaries, selected life events, repeated short-term states. | Default last 30-90 days, with at least multiple supporting records. | No, until the user confirms specific profile items. | Yes. It is a candidate summary and must be reviewed. | Not directly. It can only create `profile_candidate` items, which must be explicitly confirmed before becoming `profile_items`. |

Important rule:

`profile_candidate_summary` must remain a candidate. It must never automatically become active `profile_items`, and it must not silently influence suggestions as a confirmed long-term preference.

## 4. Summary sources

Existing records that can be summarized:

- `raw_inputs`: useful when summarizing recent input flow, but should not be the default source for normal context because raw text may include sensitive or noisy material.
- `tasks`: suitable for daily summaries, weekly reviews, action carry-over, and unresolved item lists.
- `short_term_states`: suitable for recent and daily summaries while active; expired states can be used only when summarizing past history.
- `life_events`: suitable for daily, weekly, and topic summaries.
- `profile_items`: suitable as confirmed context, but summaries must not rewrite or weaken the fact that only confirmed profile items are active.
- `ai_parse_results`: only for debugging, parser quality analysis, or smoke-test review. It should not be used as normal user context.

Records that must be excluded:

- Deleted records.
- Rejected extracted items.
- Expired short-term states, unless the user is explicitly summarizing past history.
- Unconfirmed profile candidates as active truth.
- Sensitive records unless the user can see the summary and the source is necessary for the requested summary.
- Raw inputs by default, unless there is a clear product reason, such as a recent-input summary or parser diagnosis.

Source selection should follow the current MVP privacy direction:

```text
Prefer formal, user-visible records
→ include raw inputs only when needed
→ keep source links
→ let the user edit or delete the summary
```

## 5. Suggested future database tables

These tables are future design suggestions only. Do not implement them in Task 10.

### `summaries`

Purpose: store user-visible generated or edited summaries.

Suggested fields:

| Field | Meaning |
|---|---|
| `id` | Stable summary id. |
| `summary_type` | One of `recent_input_summary`, `daily_summary`, `weekly_review_summary`, `topic_summary`, `profile_candidate_summary`. |
| `title` | User-visible title, such as "Today summary - 2026-06-05". |
| `content` | Summary text shown to the user. |
| `time_range_start` | Start of summarized range, nullable for manually selected source sets. |
| `time_range_end` | End of summarized range, nullable for manually selected source sets. |
| `status` | `active`, `candidate`, `edited`, `archived`, `deleted`, or `superseded`. |
| `generated_by` | `ai`, `user`, `system_rule`, or future provider/model id. |
| `confidence` | Optional model confidence or system quality score. |
| `created_at` | Creation time. |
| `updated_at` | Last system or user update time. |
| `user_edited_at` | Last user edit time, nullable. |
| `deleted_at` | Soft-delete time, nullable. |

Possible later fields:

- `model_name`
- `prompt_version`
- `source_count`
- `paused_from_auto_update`
- `supersedes_summary_id`

### `summary_sources`

Purpose: make every summary traceable to source records.

Suggested fields:

| Field | Meaning |
|---|---|
| `id` | Stable source-link id. |
| `summary_id` | References `summaries.id`. |
| `source_table` | Source table name, such as `tasks` or `life_events`. |
| `source_record_id` | Id of the source record. |
| `source_status_at_generation` | The source record's status when the summary was generated. |
| `created_at` | Link creation time. |

This table is important because user trust depends on being able to ask:

> Which records did the app use to generate this summary?

## 6. Status model

Suggested summary statuses:

| Status | Meaning |
|---|---|
| `active` | The current valid summary for its type/range/topic. It can be considered by the future Context Builder. |
| `candidate` | A draft or profile-candidate summary that requires user review before affecting anything important. |
| `edited` | The user changed the summary text. It should be treated as more trusted than the original generated version, but still linked to sources. |
| `archived` | Kept for history, but normally excluded from current context. |
| `deleted` | Soft-deleted by the user. It must be excluded from context and summary regeneration unless the user explicitly restores it. |
| `superseded` | Replaced by a newer summary for the same range/topic. Excluded from normal context, but available for history or restore. |

Status transitions should be conservative:

```text
candidate → active
active → edited
active/edited → archived
active/edited → superseded
any non-deleted status → deleted
superseded/archived → active only through explicit restore
```

## 7. User control

The user should control summaries in the memory area, not in a hidden AI system layer.

User controls should include:

- View summaries by type, date, and topic.
- Edit summary content directly.
- Delete summaries.
- Regenerate summaries from the same visible source records.
- Restore a previous summary when a new generated summary is worse.
- Pause automatic summary generation.
- See which records were used to generate a summary.

Conceptual adaptation from SillyTavern:

- "Current summary" becomes the active summary for a date, topic, or recent input range.
- "Restore previous" becomes restoring a superseded summary version.
- "Pause" becomes disabling automatic generation for a summary type or topic.
- "Injection template / injection position" becomes a future Context Builder rule: summaries should be placed in a separate context section, not mixed into confirmed profile or current task sections.

The app should avoid hidden memory behavior. If a summary can affect future AI replies, the user should be able to find, read, edit, and delete it.

## 8. Generation triggers

Possible future generation triggers:

- Manually triggered by the user.
- After N raw inputs.
- At end of day.
- At end of week.
- Before context gets too large.
- Before a user asks for a review, such as "帮我总结今天" or "复盘这周".

MVP recommendation for triggers:

- Automatic daily/weekly generation can be delayed.
- First implementation should be manual or simple rule-based.
- No autonomous agent behavior yet.
- If an automatic trigger is later added, it should generate a visible draft and allow deletion or regeneration.

Suggested conservative first trigger:

```text
User taps "Generate today's summary"
→ app selects today's visible records
→ AI creates a daily_summary candidate or active summary
→ user can edit/delete/regenerate
```

## 9. Prompt design

All summary prompts must instruct the model to:

- Do not invent facts.
- Preserve uncertainty.
- Do not turn one-time events into long-term profile.
- Keep summaries concise.
- Cite source record ids conceptually.
- Mark profile-level observations as candidates only.

### Recent input summary prompt

```text
You are summarizing recent user inputs for a personal memory and action app.

Use only the provided source records. Do not invent facts.
Preserve uncertainty and unresolved items.
Do not turn one-time events into long-term user profile.
Keep the summary concise.
For each important point, include conceptual source ids in brackets, such as [raw_inputs:abc] or [tasks:t1].

Output:
- Summary:
- Open items:
- Possible follow-up questions:

Source records:
{{source_records}}
```

### Daily summary prompt

```text
You are generating a daily summary for a personal memory and action app.

Use only today's visible, non-deleted source records.
Summarize tasks, short-term states, and useful life events.
Do not include rejected items.
Do not treat today's mood, fatigue, delay, or one-time event as a long-term habit.
Mention uncertainty when a record is unclear.
Keep the summary concise and user-readable.
Include conceptual source ids for important claims.

Output:
- Today at a glance:
- Completed or progressed:
- Still open:
- Short-term state context:
- Useful life events:

Source records:
{{source_records}}
```

### Weekly review summary prompt

```text
You are generating a weekly review summary for a personal memory and action app.

Use only visible, non-deleted source records from the selected week.
Do not infer behavior patterns unless the source records explicitly support a cautious candidate.
Do not create active long-term profile.
Separate facts from possible observations.
Keep the summary concise.
Include conceptual source ids for important claims.

Output:
- Week overview:
- Main actions:
- Repeated situations, if directly supported:
- Unresolved items:
- Candidate observations for user review only:

Source records:
{{source_records}}
```

### Profile candidate summary prompt

```text
You are generating profile candidates for a personal memory and action app.

Use only the provided source records.
Do not create active profile items.
Do not turn one-time events into stable preferences, habits, or traits.
A profile-level observation must be marked as candidate only and should include supporting source ids.
If support is weak, say "insufficient evidence".
Keep the output concise.

Output:
- Candidate profile observations:
  - content:
  - why it may matter:
  - supporting source ids:
  - confidence:
  - requires user confirmation: true
- Insufficient-evidence observations:

Source records:
{{source_records}}
```

## 10. How summaries enter future context

The future Context Builder may use summaries only under controlled rules:

- Include only `active` or user-`edited` summaries.
- Include only summaries relevant to the current user intent.
- Exclude `deleted` summaries.
- Exclude `superseded` summaries unless the user explicitly asks for history or restore.
- Exclude `archived` summaries from normal suggestions.
- Place summaries in a separate context section, such as `User-visible summaries`.
- Do not mix summaries into confirmed profile items.
- Do not let summaries override current tasks, active short-term states, or confirmed profile items.
- Do not use `profile_candidate_summary` as active context unless the user is reviewing candidates.

Suggested future context order:

```text
1. Current user input
2. Current tasks and active short-term states
3. Confirmed profile items
4. Relevant active summaries
5. Source ids / explanation metadata
```

This keeps summaries as compressed supporting context, not as the source of truth.

## 11. Risks

| Risk | Why it matters | Mitigation |
|---|---|---|
| Hallucination | The model may add facts that never happened. | Use source-bounded prompts, require source ids, show summaries to users, allow edit/delete/regenerate. |
| Over-compression | Important nuance may disappear. | Keep source links, allow users to inspect source records, use short summaries for context but keep formal records as truth. |
| Losing important details | A summary may omit dates, task owners, or uncertainty. | Use structured sections such as open items, unresolved items, and uncertainty notes. |
| Turning one-time events into fake patterns | "I was tired today" could become "user is often low energy". | Prompts must prohibit one-time-to-profile conversion; `profile_candidate_summary` remains candidate only. |
| Preserving sensitive data too long | Summaries may keep sensitive information after the original context should fade. | Respect deletion, support expiry/archival, exclude sensitive records unless user-visible and necessary. |
| Conflicting with user-deleted records | A summary could preserve content from a deleted source. | When a source record is deleted, mark dependent summaries as stale, superseded, or needing regeneration. |
| Stale summaries affecting current suggestions | Old summaries may mislead the AI about current state. | Exclude superseded/archived summaries; prefer current tasks and active short-term states; show generation date and range. |
| Raw input leakage | Raw text may contain sensitive details not needed for context. | Prefer formal records; include raw inputs only for recent-input summaries or parser debugging. |
| User confusion about authority | Users may think summaries are confirmed profile. | Display summary type/status clearly; separate summaries from confirmed profile items. |

## 12. MVP recommendation

Do not implement summaries immediately if the current app still needs stabilization.

When implementation becomes worthwhile:

1. Start with `recent_input_summary` or `daily_summary`.
2. Keep generation manual or simple rule-based first.
3. Store summaries as visible records.
4. Link summaries to source records.
5. Allow users to edit, delete, regenerate, and restore previous versions.
6. Do not implement vector search yet.
7. Do not implement behavior pattern inference yet.
8. Do not implement automatic long-term profile evolution yet.
9. Keep `profile_candidate_summary` as review-only candidate material.

The smallest useful first version is:

```text
Generate today's summary
→ use today's visible tasks, active short-term states, and life events
→ create a user-visible daily_summary
→ show source records
→ allow edit/delete/regenerate
```

This gives the app a useful memory-compression layer while preserving the core MVP rule:

> Summaries can help the AI remember less noisily, but they must never silently become long-term truth about the user.
