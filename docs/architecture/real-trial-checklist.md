# Phase 3 Real Trial Checklist

Date range: __________ to __________
Tester: __________
Build / device: __________
Parser mode: mock / real API
API proxy: not used / http://127.0.0.1:8787 / other: __________

## Goal

Use the app for 3 continuous days with real personal inputs, then decide whether
the MVP is ready for broader trial.

This checklist does not measure whether the app is "smart enough" in every
future scenario. It measures whether the current MVP loop is usable:

```text
natural-language input
-> AI parse result
-> extracted items
-> confirm / edit / reject
-> local memory
-> home suggestion
-> memory view / delete / undo check
```

## Trial Rules

- Use real inputs, not only artificial test sentences.
- Enter at least 5 natural-language inputs per day.
- Cover at least 2 task creates per day.
- Cover at least 1 task update per day.
- Cover at least 1 short-term state per day.
- Cover at least 1 life event per day.
- Cover at least 1 profile candidate during the 3-day trial.
- Check whether bad saves can be rejected, deleted, or undone.
- Record uncomfortable moments in plain language.
- Do not add new product features during the trial unless a P0 blocker appears.

## What To Watch

### Parser Accuracy

- Did the app classify future arrangements as `task_create`?
- Did it classify completion, cancellation, or postponement as `task_update`?
- Did it keep temporary feelings or body states as `short_term_state`?
- Did it avoid turning one-time events into long-term profile facts?
- Did normal questions stay as `general_answer` unless they also contained a
  task, state, event, or profile candidate?

### User Control

- Could you understand what the app wanted to save?
- Could you edit wrong extracted items before confirming?
- Could you reject items that should not be saved?
- Could you delete saved memories later?
- Did profile candidates require explicit confirmation?

### Home Suggestion Usefulness

- Did the home suggestion use today's tasks, overdue tasks, short-term states,
  and confirmed profile items?
- Did the explanation make it clear why the suggestion appeared?
- Did deleted, pending, expired, or rejected records stay out of suggestions?
- Did the suggestion feel helpful, neutral, annoying, or wrong?

### Privacy And Trust

- Did any screen expose sensitive raw input in a place where it felt unnecessary?
- Did logs or error messages reveal raw personal text?
- Did the app make clear which content was saved as memory?
- Did any automatic save feel too aggressive?

## Day 1

Date: __________
Device: __________
Parser mode: mock / real API

### Required Inputs

| # | Input | Expected type(s) | Actual type(s) | User action | Result |
|---|---|---|---|---|---|
| 1 | | task_create | | confirm / edit / reject | |
| 2 | | task_create | | confirm / edit / reject | |
| 3 | | task_update | | confirm / edit / reject | |
| 4 | | short_term_state | | auto-save / edit / delete | |
| 5 | | life_event | | auto-save / confirm / reject | |

Optional extra inputs:

| # | Input | Expected type(s) | Actual type(s) | Note |
|---|---|---|---|---|
| 6 | | | | |
| 7 | | | | |

### Checks

- [ ] At least 5 real natural-language inputs were entered.
- [ ] At least 2 tasks were created or confirmed.
- [ ] At least 1 task update was tested.
- [ ] At least 1 short-term state appeared in memory or suggestion context.
- [ ] At least 1 life event was saved, confirmed, or rejected.
- [ ] At least 1 wrong or unwanted extracted item was rejected.
- [ ] At least 1 saved item was deleted or undone.
- [ ] Home suggestion was checked after saving records.
- [ ] Memory pages were checked for tasks, states, events, and profiles.

### Observations

Most useful moment:

Most confusing moment:

Bad save or wrong parse:

Delete / undo result:

Home suggestion rating: useful / okay / wrong / annoying

What should be fixed before Day 2:

## Day 2

Date: __________
Device: __________
Parser mode: mock / real API

### Required Inputs

| # | Input | Expected type(s) | Actual type(s) | User action | Result |
|---|---|---|---|---|---|
| 1 | | task_create | | confirm / edit / reject | |
| 2 | | task_create | | confirm / edit / reject | |
| 3 | | task_update | | confirm / edit / reject | |
| 4 | | short_term_state | | auto-save / edit / delete | |
| 5 | | life_event | | auto-save / confirm / reject | |

Optional extra inputs:

| # | Input | Expected type(s) | Actual type(s) | Note |
|---|---|---|---|---|
| 6 | | profile_candidate | | |
| 7 | | general_answer | | |

### Checks

- [ ] At least 5 real natural-language inputs were entered.
- [ ] At least 2 tasks were created or confirmed.
- [ ] At least 1 task update was tested against an existing task.
- [ ] At least 1 short-term state affected or did not affect suggestions as expected.
- [ ] At least 1 life event was visible in memory management.
- [ ] At least 1 profile candidate required explicit confirmation.
- [ ] At least 1 confirmed profile item appeared in suggestion reasoning.
- [ ] At least 1 deleted item stayed out of home suggestions.
- [ ] A normal question did not create unwanted memory.

### Observations

Most useful moment:

Most confusing moment:

Bad save or wrong parse:

Delete / undo result:

Home suggestion rating: useful / okay / wrong / annoying

What should be fixed before Day 3:

## Day 3

Date: __________
Device: __________
Parser mode: mock / real API

### Required Inputs

| # | Input | Expected type(s) | Actual type(s) | User action | Result |
|---|---|---|---|---|---|
| 1 | | task_create | | confirm / edit / reject | |
| 2 | | task_create | | confirm / edit / reject | |
| 3 | | task_update | | confirm / edit / reject | |
| 4 | | short_term_state | | auto-save / edit / delete | |
| 5 | | life_event | | auto-save / confirm / reject | |

Optional extra inputs:

| # | Input | Expected type(s) | Actual type(s) | Note |
|---|---|---|---|---|
| 6 | | mixed types | | |
| 7 | | general_answer | | |

### Checks

- [ ] At least 5 real natural-language inputs were entered.
- [ ] At least 2 tasks were created or confirmed.
- [ ] At least 1 task completion, cancellation, or postponement was tested.
- [ ] At least 1 short-term state expired, was deleted, or was excluded correctly.
- [ ] At least 1 life event was checked in memory management.
- [ ] At least 1 profile candidate from the trial was confirmed or rejected.
- [ ] At least 1 bad save was corrected through edit, reject, delete, or undo.
- [ ] Home suggestion was checked with multiple saved memories present.
- [ ] The app still felt understandable after 3 days of data.

### Observations

Most useful moment:

Most confusing moment:

Bad save or wrong parse:

Delete / undo result:

Home suggestion rating: useful / okay / wrong / annoying

What should be fixed before broader trial:

## Final Review

### Quantitative Summary

| Metric | Count |
|---|---:|
| Total real inputs | |
| Task creates tested | |
| Task updates tested | |
| Short-term states tested | |
| Life events tested | |
| Profile candidates tested | |
| General answers tested | |
| Wrong parses | |
| Bad saves | |
| Successful edits | |
| Successful rejects | |
| Successful deletes / undos | |
| Useful home suggestions | |
| Wrong or annoying home suggestions | |

### Decision

- [ ] Ready for broader personal trial.
- [ ] Needs fixes, but core loop is usable.
- [ ] Not ready; core loop breaks trust.

### Top Issues

| Priority | Issue | Example input | Impact | Suggested next step |
|---|---|---|---|---|
| P0 | | | | |
| P1 | | | | |
| P2 | | | | |

### Keep

What should not be changed because it already works well:

### Change

What should be improved before the next phase:

### Learn

This trial should answer one product question:

> Are users willing to tell the app real personal things because they can see,
> correct, delete, and benefit from what it remembers?
