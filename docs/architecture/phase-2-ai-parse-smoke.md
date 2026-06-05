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
