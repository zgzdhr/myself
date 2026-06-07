# Phase 3 D0 Handoff

Date: 2026-06-07

## Current State

Phase 3 D0 is complete.

D0's job was to calibrate Chinese semantic classification before continuing with `current_suggestion` improvements. The work clarified how the parser should classify Chinese natural language into the 6 MVP item types, then updated the prompt, sample set, smoke checks, and project memory documents around those rules.

## What Changed

- Added `docs/architecture/chinese-semantic-classification-rules.md` as the formal D0 rule document.
- Updated `apps/api/src/services/parserPrompt.ts` with Chinese semantic boundary rules.
- Updated `apps/api/src/services/parserSampleSet.ts` with D0 regression samples.
- Updated `apps/api/scripts/smokeParseSamples.ts` to reject fabricated ISO dates for more vague Chinese time phrases.
- Added tests in:
  - `apps/api/test/parserPrompt.test.ts`
  - `apps/api/test/parserSampleSet.test.ts`
  - `apps/api/test/smokeParseSamples.test.ts`
- Updated smoke and verification docs:
  - `docs/architecture/phase-2-ai-parse-smoke.md`
  - `docs/architecture/deepseek-smoke-test.md`
  - `docs/architecture/current-verification.md`
- Updated project direction docs:
  - `AGENTS.md`
  - `2026-06-05-phase3_副本.md`

## D0 Rules To Preserve

- Do not classify by keywords alone; classify by future usefulness.
- Future arrangements, appointments, accepted invitations, and reminders are usually `task_create`.
- Social and entertainment arrangements can still be tasks.
- Current or recent condition is `short_term_state`, such as location, energy, mood, physical condition, availability, or cognitive state.
- Past experience or event is usually `life_event`.
- One-off `life_event` evidence must not automatically become `profile_candidate`.
- Stable preference, working style, repeated background, or explicit self-rule can become `profile_candidate`, but still requires user confirmation before becoming formal profile memory.
- Ordinary answers and search-like questions remain `general_answer` and are not saved by default.
- Vague time phrases preserve `due_time_text`; do not invent exact ISO dates.

## Verification

Latest D0 verification:

```bash
cd apps/api
npm run typecheck
npm test
API_BASE_URL=http://127.0.0.1:8791 npm run smoke:parse
```

Result:

- `npm run typecheck`: pass.
- `npm test`: pass, 53 tests.
- Real DeepSeek smoke: 44 samples checked, 44 pass, 0 need review, 0 type mismatch, 0 schema error.

## Next Recommended Work

### D1: `current_suggestion` Ranking And Explanation

Read first:

- `2026-06-05-phase3_副本.md`
- `AGENTS.md`
- `apps/mobile/lib/features/context/context_builder.dart`
- `apps/mobile/lib/features/home/home_suggestion_service.dart`
- `apps/mobile/test/features/context/context_builder_test.dart`

Suggested D1 boundary:

- Improve ranking for current suggestions.
- Make the explanation of "why this suggestion" clearer.
- Keep the implementation rule-based and testable.
- Do not add LLM rerank, vector search, deep personal Q&A, or auto profile evolution.

### D2: `memory_explanation` Design

D2 can be handled after D1 and is relatively independent.

Suggested D2 boundary:

- Design or implement a small explanation layer for memory usage.
- Focus on rule-based explanation first.
- Keep sensitive raw input out of logs and debug output.
- Do not connect this to a full long-chat or deep-advice page yet.

## Source Drafts Kept Outside Commit

These original D0 discussion drafts should stay available as source material, but they are not part of the committed implementation unless explicitly needed later:

- `2026-06-07-phase3_d0.md`
- `2026-06-07-phase3_d0_reward.md`
- `2026-06-07-phase3_d0_update.md`

## Suggested Skills For Next Agent

- `superpowers:executing-plans` for following the written D1/D2 plan.
- `superpowers:test-driven-development` for changing ranking or explanation behavior.
- `superpowers:verification-before-completion` before claiming D1 or D2 is done.
- `handoff` when creating the next phase transition note.
