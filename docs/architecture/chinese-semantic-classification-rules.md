# Chinese Semantic Classification Rules

Date: 2026-06-07  
Scope: Phase 3 D0 semantic calibration for the parser.

## Goal

D0 defines how the app classifies Chinese natural-language input before the
parser prompt, sample set, and smoke tests are expanded. The core question is:

```text
How should this sentence be used in the future?
```

The parser must not classify by keywords alone. Words such as "记得", "提醒我",
"回头", and "有空" are weak signals, not final decisions.

## Item Types

### `task_create`

Create a task when the user describes a future action, agreed arrangement,
appointment, preparation step, or reminder.

Use `task_create` for social and entertainment plans too, as long as the event
is future-facing and the user needs to participate.

Examples:

| Input | Expected | Note |
|---|---|---|
| 晚上同学约我去网吧，我同意了 | `task_create` | Future social arrangement, not `life_event`. |
| 晚上和妹妹去酒吧 | `task_create` | Future entertainment plan. |
| 今晚上要和同学吃烤鱼 | `task_create` | Same-day evening arrangement. |
| 过会儿提醒我给客户发消息 | `task_create` | Vague near-term reminder. |
| 回头把会议纪要发给团队 | `task_create` | Clear action, vague time. |
| 等我到酒店后给王总回电话 | `task_create` | Conditional future task. |

Current D0 behavior:

- Preserve vague time in `due_time_text`.
- Do not invent `due_time_iso` for vague or conditional time.
- When the user says "今晚", "晚上", "下午", or similar same-day time words
  without another date, prefer today's local calendar date unless surrounding
  context clearly points elsewhere.
- Recurring expressions such as "每天" and "偶尔" may become task candidates,
  but D0 does not implement a full recurrence/reminder system.

### `task_update`

Use `task_update` when the user changes an existing task: complete, cancel,
delay, or edit.

Examples:

| Input | Expected | Note |
|---|---|---|
| 王总那个事做完了 | `task_update` | Complete action, target may need resolution. |
| 明天会议取消 | `task_update` | Cancel action. |
| 下午开会的事情取消了 | `task_update` | Cancel existing afternoon meeting. |
| 今天好累，健身不想去了 | `task_update` + `short_term_state` | Possible cancellation plus energy state. |
| 客户沟通推到后天 | `task_update` | Delay action with new time text. |
| 那个事终于搞定了 | `task_update` | Vague target; app must resolve or ask. |

Current D0 behavior:

- The parser should output `update_action`.
- Vague references such as "那个事" must stay in `target_text`.
- The parser must not invent a target task.
- D0 does not change the mobile task status model.

### `short_term_state`

Use `short_term_state` for temporary current or recent context that can affect
today's suggestions.

Semantic tags may include:

| Tag | Meaning |
|---|---|
| `location_state` | Current location or movement, such as 在路上 or 在办公室. |
| `energy_state` | Energy level, such as 很累 or 精神好. |
| `mood_state` | Mood, such as 开心 or 焦虑. |
| `physical_state` | Body condition, such as 腰酸背疼. |
| `availability_state` | Availability, such as 不方便接电话. |
| `cognitive_state` | Mental/work clarity, such as 项目有点乱. |

D0 records these as semantic hints or tags only. It does not add new item types.

### `life_event`

Use `life_event` for things that already happened: experiences, lessons,
mistakes, observations, or context behind a task.

`life_event` is evidence for future reflection and self-evolution, but it must
not automatically become `profile_candidate`.

Examples:

| Input | Expected | Note |
|---|---|---|
| 今天下午开会，老板要求改方案 | `life_event` | Happened already; may explain a task. |
| 上次运动动作不标准 | `life_event` | Past lesson. |
| 晚上跑了 70 公里 | `life_event` | Past physical event. |

### `profile_candidate`

Use `profile_candidate` for stable preferences, habits, background, goals, or
work style. It is always a proposal and must require user confirmation.

Examples:

| Input | Expected | Note |
|---|---|---|
| 我不喜欢太频繁的提醒 | `profile_candidate` | Stable reminder preference. |
| 英语一直很重要 | `profile_candidate` | Long-term value or goal. |
| 运动时我更重视动作质量 | `profile_candidate` | Stable principle, but confirm first. |

Do not infer active profile from one-off emotions, one-off failures, or a single
`life_event`.

### `general_answer`

Use `general_answer` for ordinary questions, search-like questions, chitchat,
or advice requests. These should not create saveable memory by default.

If an input contains both a question and a saveable item, split them.

Example:

```text
你看用不用今晚回家提醒我拉伸一下？
```

This may produce:

- `general_answer`: answer the advice request.
- `task_create`: remind user to stretch tonight if the task is explicit enough.

## Classification Priority

Use this order when a sentence is ambiguous:

```text
1. Existing task change -> task_update
2. Future action / arrangement / reminder -> task_create
3. Current or recent state -> short_term_state
4. Past event / lesson / experience -> life_event
5. Stable preference / habit / background -> profile_candidate
6. Ordinary question / search / chitchat -> general_answer
```

One user input may produce multiple items.

## Current Non-goals

D0 does not implement:

- Reminder scheduling.
- Repeating tasks.
- Completed/cancelled task cleanup settings.
- Dual reminders for vague delays.
- Automatic profile evolution from life events.
- Deep advice or long-form chat pages.
- Vector search, cloud sync, or a full AI agent.
