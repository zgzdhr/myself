# Open-source research: calendar, recurring tasks, and sedentary sessions

Date: 2026-07-06

This note records the source-level research done before redesigning the next task
map. It should be read together with `docs/architecture/phase-5-task-map.md`.

## Why this research happened

The next product direction was adjusted from account/cloud/release work toward:

- a unified calendar-like task view;
- daily recurring tasks created through the normal task creation flow;
- weekly calendar display with draggable task/time blocks;
- a first-page "start sedentary session" action, replacing the earlier
  "start studying" wording.

The key design question was whether recurring tasks, calendar blocks, and focus
or sedentary reminders should share one model or remain separate.

## Temporary repositories inspected

The following mature open-source projects were temporarily downloaded under
`/private/tmp` for read-only inspection. They are not project dependencies.

- `/private/tmp/super-productivity`
  - Repo: `https://github.com/super-productivity/super-productivity`
  - Inspected repeat-task config, planner projection, reminders, focus mode, and
    break reminder code/tests.
- `/private/tmp/tasks-org2`
  - Repo: `https://github.com/tasks/tasks`
  - Inspected Android task recurrence, RRULE handling, repeat completion, and
    alarm rescheduling.
  - Note: an earlier clone attempt at `/private/tmp/tasks-org` failed during
    transfer; `/private/tmp/tasks-org2` succeeded.
- `/private/tmp/uhabits`
  - Repo: `https://github.com/iSoron/uhabits`
  - Inspected habit model, frequency, weekday reminder, history chart, and
    reminder scheduler.
- `/private/tmp/vikunja`
  - Repo: `https://github.com/go-vikunja/vikunja`
  - Inspected repeat fields, repeat modes, completion behavior, reminder updates,
    and recurrence tests.

These downloads were only for local reference during planning. Do not assume they
exist in a future session.

## Findings

### Super Productivity

Useful ideas:

- Recurring tasks are represented as repeat configuration plus materialized task
  instances, not as a single task endlessly edited in place.
- Repeat instances need deterministic identity. Super Productivity avoids
  duplicates by deriving an expected task id from repeat config and date.
- Deleted individual repeat instances need an exception list, otherwise the app
  will recreate something the user intentionally removed.
- Missed days are a real bug class. Their tests cover opening the app after a
  scheduled repeat day was skipped.
- Break reminders are driven by tracked work time and current task/session state,
  not by posture sensors.

Design implication for this project:

- Use `recurring_rule_id + occurrence_date` as a uniqueness boundary.
- Add tests for missed days, future start dates, deleted single-day instances,
  and duplicate prevention.
- "Start sedentary session" should be a manual session timer first, not sensor
  detection.

### Tasks.org

Useful ideas:

- Tasks.org uses iCalendar-style `RRULE` recurrence for mature repeat rules.
- Completing a repeating task computes the next due date and reschedules alarms.
- Reminders move together with due dates.
- Time zone and DST behavior require explicit testing.

Design implication for this project:

- Do not implement full RRULE in the first version. Start with daily repeat only.
- Keep a path open for a future RRULE-like model, but do not expose that
  complexity now.
- When repeat instances have a time, reuse the existing task reminder pipeline.

### Loop Habit Tracker

Useful ideas:

- Habits are modeled as `habit + daily entry/checkmark`, not as a new task every
  day.
- It has simple frequency and weekday reminder primitives.
- Its history chart is optimized for long-term habit continuity.

Design implication for this project:

- "Every day go running" can look like a task today, but long-term streaks and
  habit scoring are a different product layer.
- First version should remain "daily recurring task instances"; do not add habit
  streaks yet.
- If habit tracking is added later, it should be a separate layer, not hidden
  inside `tasks`.

### Vikunja

Useful ideas:

- Vikunja keeps repeat fields directly on task records: `repeat_after`,
  `repeat_mode`, reminders, due/start/end dates.
- Marking a recurring task done reopens it and moves dates/reminders forward.
- It distinguishes default interval repeat, monthly repeat, and repeat from
  current date.
- It validates maximum repeat intervals to avoid pathological schedules.

Design implication for this project:

- Editing the same task in place is simpler but loses clean per-day history.
- Because this app values memory, review, and explainability, materialized daily
  instances are a better first fit than Vikunja-style in-place reopening.
- Validate repeat ranges even in v1.

## Revised product decisions

- Build a unified calendar, not separate task-calendar and plan-calendar.
- Calendar shows:
  - normal tasks;
  - daily recurring task instances;
  - existing `schedule_blocks` from AI time planning;
  - sedentary sessions where useful.
- Weekly calendar must support dragging task/time blocks in this phase.
- Do not add separate "new daily recurring task" or "start studying" entry
  points.
- Creating a recurring task should use the same flow as creating a normal task,
  with an option such as "repeat task" and a date/time range.
- Rename the session idea to "start sedentary session" and put it on the first
  page.
- Account, cloud, domestic deployment, and release-readiness work remain
  important but move behind this usability phase.

## Implementation warnings for future agents

- Do not auto-convert repeated behavior into long-term profile memory.
- Do not make `/parse` responsible for complex recurrence in the first version.
- Do not hide repeat generation inside UI widgets; use a small service that can
  be tested without rendering.
- Do not let dragging a calendar block silently complete, cancel, or delete a
  task. Dragging should update schedule placement or task due time only through
  explicit, understandable rules.
- Preserve local-first behavior. Notification and session logic must still work
  without account login.
