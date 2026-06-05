# DeepSeek Smoke Test

## Date

2026-06-05

## Purpose

Verify that the API proxy can call DeepSeek and return valid schema output for all MVP parse scenarios.

## Environment

| Variable | Value |
|---|---|
| `DEEPSEEK_API_KEY` | configured (not committed) |
| `DEEPSEEK_BASE_URL` | `https://api.deepseek.com` |
| `DEEPSEEK_MODEL` | `deepseek-v4-flash` |
| `API_PORT` | `8787` |

## Model Compatibility

| Feature | Sent in Request | Accepted |
|---|---|---|
| `model: "deepseek-v4-flash"` | yes | yes |
| `response_format: { type: "json_object" }` | yes | yes |
| `thinking: { type: "disabled" }` | yes | yes |
| `temperature: 0.1` | yes | yes |
| `max_tokens: 1800` | yes | yes |

The `thinking: { type: "disabled" }` option is accepted without error — no modification was needed.

## Test Results

All 8 smoke samples from the parser sample set passed against the live DeepSeek API:

```
PASS tomorrow_task (明天任务)        -> task_create
PASS today_state (今天状态)          -> short_term_state
PASS long_term_preference (长期偏好) -> profile_candidate
PASS life_event (生活事件)           -> life_event
PASS ordinary_question (普通问答)    -> general_answer
PASS vague_time (模糊时间)           -> task_create
PASS multiple_tasks (多个任务混合)   -> task_create
PASS one_off_emotion (不应保存的情绪表达) -> short_term_state
```

## Single Sample Verification

The specific MVP sample `"明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。"` produced the expected result:

- **task_create**: "明天上午联系王总" with `due_time_text: "明天上午"`
- **short_term_state**: "今天很累" with `need_user_confirm: false` (auto-save eligible)
- **profile_candidate**: "不喜欢太频繁的提醒" with `need_user_confirm: true` (confirmation required)

## Schema Validation

All returned JSON payloads pass the Zod `parseResultSchema` without errors. The schema enforces:

- Required fields: `type`, `source_text`, `tags`, `confidence`, `need_user_confirm`
- `confidence` clamped to `[0, 1]`
- `profile_candidate` items must have `need_user_confirm === true`
- `.strict()` mode rejects unknown fields

## Privacy Verification

The privacy logging test (`test/privacyLogging.test.ts`) confirms that parser error logs contain `requestId`, `errorType`, and `statusCode` but **never raw user text**.

## How to Re-run

```bash
# Start the API server
cd apps/api
npm run dev

# In another terminal, run the smoke test
npm run smoke:parse
```

## Notes

- No API key changes were needed — the existing `.env` configuration works.
- The `deepseek-v4-flash` model name is accepted and produces correct, structured JSON output.
- No retry or fallback was triggered during the test run — all first-attempt responses were valid.
