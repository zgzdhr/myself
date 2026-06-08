# Memory Explanation Design

Date: 2026-06-08

## Goal

`memory_explanation` answers a narrow user question:

> 这个建议用了哪些记忆？

The first version is rule-based. It explains which user-visible, confirmed
records contributed to `current_suggestion`. It does not call an LLM, perform
vector search, infer hidden patterns, or explain from raw input.

## Product Boundary

The explanation layer is part of user control. It should make memory usage
inspectable without overstating what the app knows.

Allowed sources for MVP:

- Confirmed tasks in the `current_suggestion` context.
- Confirmed and unexpired `short_term_states`.
- Confirmed `profile_items`.

Excluded sources:

- `raw_inputs`.
- `ai_parse_results.rawJson`.
- Pending, rejected, deleted, expired, or archived records.
- Unconfirmed `profile_candidate` extracted items.
- Future summaries, vector matches, behavioral patterns, or LLM-derived claims.

## Current Implementation

`ContextBuilder.buildCurrentSuggestion` now returns:

```dart
List<ContextMemoryExplanation> memoryExplanations
```

Each explanation has:

- `sourceType`: stable table-like type, such as `tasks`.
- `sourceId`: formal record id.
- `label`: user-visible source label, such as `已确认任务：联系王总`.
- `reason`: rule explanation, such as `今天到期，参与当前建议排序。`

Example UI copy:

```text
这个建议使用了：
1. 已确认任务：联系王总
   今天到期，参与当前建议排序。
2. 短期状态：今天有点累
   状态仍在有效期内，参与当前建议语气调整。
3. 长期偏好：用户不喜欢太频繁的提醒
   用户已确认的长期画像，参与当前建议语气调整。
```

## Rule Set

Tasks:

- No due time: `没有明确到期时间，但仍是已确认任务，参与当前建议排序。`
- Overdue: `已经逾期，参与当前建议排序。`
- Due today: `今天到期，参与当前建议排序。`
- Future 7 days: `未来 7 天内到期，参与当前建议排序。`

Short-term states:

- `状态仍在有效期内，参与当前建议语气调整。`

Profile items:

- `用户已确认的长期画像，参与当前建议语气调整。`

These explanations intentionally describe the local rule that selected the
record. They do not say the app discovered a long-term pattern unless the source
is a confirmed profile item.

## Privacy And Debugging

User-facing explanation may show formal record text because these records are
already visible in the memory management UI.

Debug output must not include user text. `ContextPackage.toDebugJson()` only
returns section counts, excluded reason counts, and `memory_explanation_counts`
grouped by `sourceType`.

Sensitive fields that must stay out of debug output:

- Raw input text.
- Extracted item `source_text`.
- Task titles, state content, and profile content.
- AI raw JSON.

## Future Upgrade Path

Later phases can add explanation entries for:

- Summary-backed context, after summary storage and source ids exist.
- Keyword or tag search, if the UI can show the matched formal record.
- Deeper advice pages, with explicit separation from homepage suggestions.

Before adding any new source type, the source must be user-visible, deletable,
and represented in debug output only as counts.
