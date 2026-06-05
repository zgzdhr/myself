# Phase 2 AI Parse Smoke Test

This note records the local commands for verifying the real DeepSeek parse loop.

## Environment

Create the ignored API env file:

```bash
cd /Users/mac/projects/cc/myself
cp .env.example apps/api/.env
open apps/api/.env
```

Replace `DEEPSEEK_API_KEY=replace_with_your_key` with the real DeepSeek key.
The key must stay in `apps/api/.env`; the Flutter app never stores it.

## Start API Proxy

```bash
cd /Users/mac/projects/cc/myself/apps/api
npm run dev
```

Health check:

```bash
curl http://127.0.0.1:8787/health
```

Expected:

```json
{"ok":true}
```

## Run The 33-Sample Parse Smoke

In another terminal:

```bash
cd /Users/mac/projects/cc/myself/apps/api
npm run smoke:parse
```

The smoke command sends the expanded Phase 3 Chinese sample set (33 entries) to
`/parse` and checks that each response contains the expected MVP item types and
avoids known bad classifications, such as turning a one-off emotion into a
long-term profile. The sample set covers task_create, task_update (complete /
cancel / delay / edit), short_term_state, life_event, general_answer,
profile_candidate, multi-intent, vague time, business trip scenarios, and
edge cases around profile_candidate boundaries.

## Phase 3 A2 Prompt Boundary Checks

The parser prompt is now tested as part of the API test suite. It must keep
these boundaries explicit:

- Return JSON only and do not output fields outside the schema-supported fields.
- Treat `profile_candidate` as a proposal only; it must not become active memory
  unless the user confirms it, and `profile_candidate.need_user_confirm` must be
  `true`.
- Ordinary questions, chitchat, and advice requests should not create saveable
  memory. Their `items` may be empty or contain only `general_answer`.
- One-time emotions and one-off events must not become long-term profile.
- Vague task references such as "那个事" must not invent a target task.
- `task_update` delay without a clear new time must not invent `due_time_iso`.

Verification:

```bash
cd /Users/mac/projects/cc/myself/apps/api
npm run typecheck
npm test
```

## Phase 3 A3 Enhanced Smoke Assertions

The `npm run smoke:parse` command now performs per-sample rule checks beyond type
matching. Each sample result includes a `ruleFailures` list and the output shows
a summary breakdown.

### Rule Checks

| Rule | Failure Condition |
|---|---|
| `profile_candidate.need_user_confirm` | Any `profile_candidate` item with `need_user_confirm !== true` |
| `source_text` non-empty | Any item with empty or whitespace-only `source_text` |
| `confidence` range | Any item with `confidence < 0` or `confidence > 1` |
| Vague time ISO fabrication | Sample id/label contains "vague"/"模糊" and item has `due_time_iso` for a vague `due_time_text` |
| General answer saves nothing | `general_answer` sample produces `task_create`, `short_term_state`, `life_event`, or `profile_candidate` |

### Output Format

```
PASS sample_id (label) -> type1, type2
REVW sample_id (label) -> type1, type2   ← type checks pass but rule failures
FAIL sample_id (label) -> actual_types   ← missing or forbidden types
ERR  sample_id (label) -> error details  ← schema / HTTP / JSON error

33 samples checked
28 pass
3 need review
1 type mismatch
1 schema error
```

### Per-Sample Error Resilience

The smoke runner now catches errors per sample instead of aborting the entire
run. A single HTTP failure, JSON parse error, or schema validation failure is
recorded for that sample and the loop continues to the next one.

## Phase 3 A4 Parser Failure Fallbacks

### DeepSeek Fetch Timeout

The DeepSeek fetch call now includes an `AbortController` timeout (default 20s).
If DeepSeek hangs or does not respond within the timeout window, the parser throws
`ParserServiceError("deepseek_request_failed", 503)`. Each retry attempt gets its
own AbortController.

### Input Length Validation

The `/parse` endpoint rejects requests where `text` exceeds 2000 characters
(`parseRequestSchema` enforces `z.string().max(2000)`).

The mobile `ExtractedItemsController.submitInput` also validates input length
before sending to the API, throwing `ParserFailure(code: "input_too_long")`.

### Existing Failure Coverage

| Failure Path | API | Mobile |
|---|---|---|
| API key missing | `ParserServiceError("missing_api_key", 503)` | Generic failure message |
| DeepSeek timeout | `ParserServiceError("deepseek_request_failed", 503)` | Generic failure message |
| DeepSeek HTTP error | `ParserServiceError("deepseek_http_error", 502/503)` | Generic failure message |
| JSON parse failure | Retry once, then 502 | `ParserFailure("invalid_response")` |
| Schema validation failure | Retry once, then 502 | `ParserFailure("invalid_response")` |
| Mobile network error | N/A | `ParserFailure("network_error")` |
| Empty input | `400 invalid_request` | `ParserFailure("empty_input")` |
| Input too long | `400 invalid_request` | `ParserFailure("input_too_long")` |

User-facing failure message: "这次我没能稳定解析成可保存的数据。你可以重试，或者先手动记录。"

## Phase 3 A5: Mobile Latin-1 Encoding Fix

iOS `_defaultPostJson` used `request.write(body)` (Latin-1) instead of
`request.add(utf8.encode(body))`. Any Chinese character in the request body
caused `UnicodeSubsetEncoder.convert` to fail, showing the generic network
error message. Fixed with explicit UTF-8 encoding. `NSAllowsLocalNetworking`
was also added to `Info.plist`.

## Mobile Smoke

iOS simulator uses the API proxy at `http://127.0.0.1:8787`.
Android emulator uses `http://10.0.2.2:8787`.

Run iOS:

```bash
cd /Users/mac/projects/cc/myself/apps/mobile
flutter run -d 9045AD68-F766-4E67-A357-847CCCB79A97
```

Run Android after starting an Android emulator:

```bash
cd /Users/mac/projects/cc/myself/apps/mobile
flutter run
```

Manual checks:

- Different inputs should produce different pending cards.
- Confirming a task should refresh `今日行动`.
- Confirming short-term state or profile candidate should refresh `记忆入口`.
- Parser failures should show a user-friendly message without raw technical
  details.
