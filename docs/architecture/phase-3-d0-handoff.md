# Phase 3 D0-D1 Handoff

Date: 2026-06-07

## Current State

Phase 3 D0 and D1 are complete.

D0's job was to calibrate Chinese semantic classification before continuing with `current_suggestion` improvements. D1's job was to implement ranking and explanation for `current_suggestion`, making home screen suggestions more stable and transparent.

D2 (`memory_explanation` design) is the recommended next step.

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

### D2: `memory_explanation` Design

D1 is complete (see below). D2 is the next step and is relatively independent.

Suggested D2 boundary:

- Design or implement a small explanation layer for memory usage.
- Focus on rule-based explanation first: which confirmed records contributed to which suggestion.
- Keep sensitive raw input out of logs and debug output.
- Do not connect this to a full long-chat or deep-advice page yet.

## Source Drafts Kept Outside Commit

These original D0 discussion drafts should stay available as source material, but they are not part of the committed implementation unless explicitly needed later:

- `2026-06-07-phase3_d0.md`
- `2026-06-07-phase3_d0_reward.md`
- `2026-06-07-phase3_d0_update.md`

---

## D1: `current_suggestion` Ranking And Explanation — Complete

Date: 2026-06-07

D1 的目標是讓首頁建議更穩定地優先處理逾期、今天、未來 7 天任務，並結合短期狀態和長期偏好調整語氣。

### Main Results

**排序規則（`HomeSuggestionService.buildSuggestions`）：**

- 任務按 `dueTime` 升序排列，最早到期的最優先。
- 取前 3 個任務生成建議，避免資訊過載。
- 無任務時提示「可以先補充一條今天最重要的事情」。

**語氣適配（上下文感知）：**

- `_hasLowEnergy`：檢測短期狀態中是否包含「累」「疲憊」等低能量關鍵詞。低能量時建議文案使用「用低阻力方式處理」而非「處理」。
- `_avoidPushyLanguage`：檢測長期畫像中是否包含「不喜歡太頻繁的提醒」等偏好。有此偏好時文案使用「可以考慮」而非「建議先」，並避免「必須」「馬上」等強勢詞。

**解釋層（`_buildReason`）：**

- reason 格式為結構化拼接：「基於任務：{標題}（時間標籤）| 當前狀態：{內容} | 長期偏好：{內容}」。
- 時間標籤根據 `dueTime` 與 `now` 的關係輸出「已逾期」「今日」或「未來 7 天」。
- 無狀態或無畫像時對應段落不出現，不拼接空字串。
- reason 不包含 raw input、source_text 或任何除錯敏感欄位。

**ContextBuilder 分類（`buildCurrentSuggestion`）：**

- `suggestionTasks`：所有活躍任務（供排序用）。
- `overdueTasks`：已逾期任務。
- `todayTasks`：今天到期或無 due time 的任務。
- `nextSevenDaysTasks`：未來到期任務。
- `activeShortTermStates`：未過期的已確認短期狀態。
- `confirmedProfileItems`：已確認的長期畫像。
- `excludedReasonCounts`：記錄被排除的條目數量及原因（deleted / rejected / pending / expired / unconfirmed_profile_candidate / raw_inputs_default_excluded）。
- `toDebugJson()` 只輸出 count 和分類資訊，不輸出任何 raw input 或正文內容。

### Files Changed

| File | Change |
|---|---|
| `apps/mobile/lib/features/context/context_builder.dart` | 新增 `buildCurrentSuggestion`、`_loadExcludedReasonCounts`、`toDebugJson` |
| `apps/mobile/lib/features/home/home_suggestion_service.dart` | 新增排序邏輯、語氣適配、結構化 reason、`_hasLowEnergy`、`_avoidPushyLanguage` |
| `apps/mobile/test/features/context/context_builder_test.dart` | 10 項測試：意圖檢測、刪除/過期/待確認排除、debug 不含敏感文字、task_update resolution、與 HomeSuggestionService 上下文一致性 |
| `apps/mobile/test/features/home/home_suggestion_service_test.dart` | 9 項測試：僅載入已確認記錄、逾期優先、低能量低阻力建議、柔和語氣、reason 含任務/狀態/畫像、不含 raw input、空任務提示、general_answer 不進入建議 |

### Verification

```bash
cd apps/mobile
flutter analyze
flutter test

cd ../api
npm run typecheck
npm test
```

Results:

| Check | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 102 tests passed, 0 failed |
| `npm run typecheck` | Pass |
| `npm test` | 53 tests passed, 0 failed |

### D1 Rules To Preserve

- 排序以 dueTime 為準，最早到期最優先，不引入優先級權重或複雜評分。
- 語氣適配是簡單的字符串匹配（低能量關鍵詞、提醒偏好關鍵詞），不引入 LLM rerank。
- reason 只引用已確認、未刪除、未過期的正式記錄，不引用 raw input 或 pending extracted_item。
- debug json 只含 count 和分類，不含任何用戶正文。
- 不修改數據庫 schema，不新增 MVP item type。

### Boundary (Not Done)

- 不做 LLM rerank、向量檢索、深度個人 Q&A。
- 不做自動長期畫像進化。
- 不根據優先級（high/medium/low）調整排序權重。
- 不為「無 due time 任務 vs 有 due time 任務」設計特殊排序策略。

---

## Suggested Skills For Next Agent

- `superpowers:executing-plans` for following the written D2 plan.
- `superpowers:test-driven-development` for changing explanation behavior.
- `superpowers:verification-before-completion` before claiming D2 is done.
- `handoff` when creating the next phase transition note.
