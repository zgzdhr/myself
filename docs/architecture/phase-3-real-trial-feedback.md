# Phase 3 Real Trial Feedback

Date: 2026-06-08
Device: Samsung Android phone
Build: Phase 3 real API debug APK
Parser mode: real API through local DeepSeek proxy

## Summary

This document records real user trial feedback from the first Android phone
trial. The core parse-confirm-save loop can be tested on device, but several
issues affect trust and daily usability.

The most important problems are time semantics, task update matching, today
filtering, pending confirmation persistence, and date-based testing tools.

## Priority Guide

- P0: Breaks trust or may lose user data.
- P1: Blocks realistic daily use or causes wrong action suggestions.
- P2: UX quality issue that should be improved after core behavior is stable.

## Feedback Items

| # | Priority | Area | Trial input / situation | Actual result | Expected result | Suggested next step |
|---|---|---|---|---|---|---|
| 1 | P1 | Task time semantics | `今晚上要和同学吃烤鱼` / user only said "晚上" without explicit date | Task stayed as pending confirmation: `晚上和同学吃烤鱼` | In normal Chinese usage, "晚上" should usually mean "今天晚上" unless context suggests another day | Update parser/time rules so same-day implicit time words such as "今晚/晚上/下午" can resolve to today's date with confidence and visible source text |
| 2 | P1 | Task update matching | Existing task: `今天下午开会`; user input: `下午开会的事情取消了` | Existing meeting task was not cancelled | Should identify this as `task_update` cancel and match the existing afternoon meeting task | Add real-world cancel expressions and target matching tests |
| 3 | P1 | Task update matching | Existing task: `今天下午开会`; user input: `今下午不用去开会了` | Successfully cancelled the task | This confirms the flow can work, but wording is brittle | Use as a passing comparison case when tightening task update matching |
| 4 | P1 | Task update plus state | Existing task: `今天下午要去健身`; user input: `今天好累呀，那个健身我不想去健身了` | Did not correctly recognize the user's intent around the fitness task | Should at least detect a possible task update and ask user to confirm whether to keep, reduce, delay, or cancel the fitness task | Treat "不想去/不去了/不想做" as possible cancellation or intention conflict when an active task matches |
| 5 | P1 | Today action filtering | Some tasks clearly described as tomorrow tasks | They appeared in today's action list | Tomorrow tasks should not appear as today's tasks unless overdue/currently actionable by explicit product rule | Fix date filtering for today actions and add tests for today/tomorrow boundaries |
| 6 | P1 | Task date precision | Future tasks and reminder-like tasks | Time display is too vague; today/tomorrow are not enough for later reminder design | Store and display concrete calendar date when possible, and preserve exact time text when exact time is not known | Improve due date/time model and UI display before reminder work |
| 7 | P2 | Home suggestion layout | Current states are joined with commas | Text looks crowded and hard to scan | Use clearer separators, spacing, or section layout | Polish home suggestion explanation formatting |
| 8 | P2 | Home suggestion layout | Today's status, current status, and long-term preferences appear connected together | The suggestion area is visually dense and not easy to understand | Separate tasks, short-term states, and long-term preferences into grouped explanation sections | Redesign suggestion explanation layout around source groups |
| 9 | P2 | Home suggestion interaction | User expects more than one AI suggestion and not only today's action | Current suggestion feels too narrow and flat | Suggestion area should be expandable and show up to 3 suggestions, using today's tasks plus relevant non-today tasks or habits when appropriate | Design expandable multi-suggestion UI after core filtering is correct |
| 10 | P2 | Today action interaction | User wants to tap today's action area | Current card is not an expandable schedule view | Today's action card should be expandable and show today's task arrangement | Add expandable today action section |
| 11 | P1 | Test tooling | Short-term state and date-related behavior need next-day validation | User would have to wait until tomorrow to verify expiration/filtering | Test builds should allow switching the app's current date | Add debug/test date switcher for Android trial builds only |
| 12 | P0 | Pending confirmation persistence | User clicks `整理`, sees pending items, then enters new text and clicks `整理` again before confirming | Previous pending confirmation content disappears from the page | Pending items should not be lost when new parse results arrive | Persist and show recent pending parse batches, at minimum the latest 3 batches requiring confirmation |
| 13 | P1 | Task edit UI | In memory management, editing a task deadline uses a manual text field | Date entry feels too empty and error-prone | Deadline editing should use date and time pickers, similar to setting an alarm | Add date/time picker for task due date editing |
| 14 | P1 | Memory deletion safety | Deleting records in memory management | Delete happens without enough confirmation | All delete actions should ask for confirmation before destructive action | Add confirmation dialog for task/state/event/profile deletion |
| 15 | P2 | Memory batch operations | User wants to clean multiple records | No batch delete flow | Memory management should support multi-select and batch delete with final confirmation | Add batch selection and batch delete after single-delete confirmation is stable |

## Product Interpretation

The trial shows that the app is no longer just a technical prototype. Users are
now testing whether it understands daily language and whether it can be trusted
not to lose or misuse personal records.

The strongest trust risks are:

- Pending confirmation content can disappear after a new parse.
- Tomorrow tasks can be shown as today's action.
- Task cancellation depends too much on exact wording.
- Vague same-day time expressions such as "晚上" are not handled naturally.

## Recommended Next Priorities

1. Preserve pending confirmation batches so user decisions are not lost.
2. Fix today/tomorrow filtering and same-day time semantics.
3. Tighten task update matching around cancel / not going / do not want to do.
4. Add a debug date switcher for real Android trial builds.
5. Improve deadline editing with date/time picker.
6. Polish home suggestion and today's action layout after the data behavior is stable.

## Documentation Follow-up

- `phase-3-verification.md` should summarize these issues during E4.
- `current-verification.md` should record the Samsung real API trial and the
  highest-priority known issues.
- `AGENTS.md` should keep only long-term product memory and next-phase
  priorities, not this full issue table.
