# Personal Memory Action System MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first Android/iOS MVP of a local-first personal memory and action整理 App that turns natural language into confirmed, editable, deletable structured records.

**Architecture:** Use a Flutter mobile app for Android/iOS, a local SQLite database for confirmed memory/action records, and a minimal TypeScript API proxy for DeepSeek calls so the API key never ships in the mobile client. The MVP keeps all user memory local by default and only sends the current input plus minimal necessary context to the AI parser.

**Tech Stack:** Flutter, Dart, Drift/SQLite, Riverpod, Node.js, TypeScript, Zod, DeepSeek API, Flutter unit/widget tests, Node test runner.

---

## 1. Product Boundary

This MVP is not a full AI companion, health assistant, CRM, project management system, or complex personal knowledge base.

It validates one core loop:

```text
User natural-language input
→ DeepSeek structured JSON
→ schema validation
→ pending extracted items
→ user confirm / edit / reject
→ local database official records
→ home suggestion from today tasks + short-term states + confirmed profile items
```

The product should feel like a personal memory and action整理 system, not merely a To-do List. Therefore the MVP includes minimal confirmed long-term profile memory, but excludes automatic profile evolution and behavior-pattern inference.

## 2. MVP Information Types

The first version supports exactly these output types:

1. `task_create`
2. `task_update`
3. `short_term_state`
4. `life_event`
5. `general_answer`
6. `profile_candidate`

Do not add more item types until these six work reliably.

## 3. Minimum Database Tables

Create these logical tables in the Flutter local database:

- `raw_inputs`: original user text and metadata.
- `ai_parse_results`: raw AI response, validation state, retry/error metadata.
- `extracted_items`: pending AI-extracted structured items awaiting user decision.
- `tasks`: confirmed tasks and task updates.
- `short_term_states`: confirmed or visible auto-recorded temporary states with expiry.
- `life_events`: confirmed event/experience records.
- `profile_items`: confirmed long-term profile facts/preferences.

Use explicit record states:

- `pending`
- `confirmed`
- `edited`
- `rejected`
- `deleted`
- `expired`
- `archived`

## 4. Recommended Repository Structure

```text
myself/
  AGENTS.md
  AI_personal_memory_action_system_design_v0.2.md
  docs/
    architecture/
    superpowers/
      plans/
  apps/
    mobile/
      lib/
        app/
        features/
          input/
          extracted_items/
          home/
          memory/
        data/
          local_db/
          parser/
        domain/
      test/
    api/
      src/
        routes/
        services/
        schemas/
      test/
```

## 5. Implementation Tasks

### Task 0: Confirm Toolchain And Create Project Skeleton

**Files:**
- Create: `apps/mobile/`
- Create: `apps/api/`
- Create: `README.md`
- Create: `.env.example`

- [ ] **Step 1: Verify local toolchain**

Run:

```bash
flutter --version
node --version
npm --version
```

Expected:

- Flutter is installed and can target Android/iOS.
- Node.js and npm are installed.

- [ ] **Step 2: Scaffold Flutter mobile app**

Run:

```bash
mkdir -p apps
cd apps
flutter create mobile
```

Expected:

- `apps/mobile/pubspec.yaml` exists.
- `apps/mobile/lib/main.dart` exists.
- `apps/mobile/android/` and `apps/mobile/ios/` exist.

- [ ] **Step 3: Scaffold TypeScript API proxy**

Run:

```bash
mkdir -p apps/api/src/routes apps/api/src/services apps/api/src/schemas apps/api/test
cd apps/api
npm init -y
npm install express zod dotenv cors
npm install -D typescript tsx @types/node @types/express
npx tsc --init
```

Expected:

- `apps/api/package.json` exists.
- `apps/api/tsconfig.json` exists.
- API source folders exist.

- [ ] **Step 4: Add environment template**

Create `.env.example`:

```bash
DEEPSEEK_API_KEY=replace_with_your_key
DEEPSEEK_BASE_URL=https://api.deepseek.com
API_PORT=8787
```

Expected:

- No real API key is committed.
- The mobile app never reads `DEEPSEEK_API_KEY` directly.

- [ ] **Step 5: Add root README**

Create `README.md` with:

```markdown
# AI Personal Memory Action System

Local-first Android/iOS MVP for turning natural language into confirmed personal memory and action records.

## Apps

- `apps/mobile`: Flutter Android/iOS app.
- `apps/api`: Minimal TypeScript DeepSeek API proxy.

## MVP Loop

Input → AI JSON parse → schema validation → extracted item confirmation → local database → home suggestion.
```

Expected:

- A new developer can understand the repo shape in under one minute.

- [ ] **Step 6: Run scaffold checks**

Run:

```bash
cd apps/mobile
flutter test
cd ../api
node -e "console.log('api scaffold ok')"
```

Expected:

- Flutter default test passes.
- API scaffold command prints `api scaffold ok`.

### Task 1: Add Mobile Dependencies And App Folders

**Files:**
- Modify: `apps/mobile/pubspec.yaml`
- Create: `apps/mobile/lib/app/`
- Create: `apps/mobile/lib/features/input/`
- Create: `apps/mobile/lib/features/extracted_items/`
- Create: `apps/mobile/lib/features/home/`
- Create: `apps/mobile/lib/features/memory/`
- Create: `apps/mobile/lib/data/local_db/`
- Create: `apps/mobile/lib/data/parser/`
- Create: `apps/mobile/lib/domain/`

- [ ] **Step 1: Add Flutter packages**

Run:

```bash
cd apps/mobile
flutter pub add flutter_riverpod drift sqlite3_flutter_libs path_provider path json_annotation uuid intl
flutter pub add -d drift_dev build_runner json_serializable flutter_lints
```

Expected:

- `pubspec.yaml` includes local database, state management, JSON, UUID, and lint dependencies.

- [ ] **Step 2: Create focused folder structure**

Run:

```bash
mkdir -p lib/app \
  lib/features/input \
  lib/features/extracted_items \
  lib/features/home \
  lib/features/memory \
  lib/data/local_db \
  lib/data/parser \
  lib/domain
```

Expected:

- Each folder has one clear responsibility.

- [ ] **Step 3: Replace default counter app with app shell**

Update `apps/mobile/lib/main.dart` to start the app through Riverpod and a small app shell.

Expected behavior:

- App launches to a home screen.
- No parser or database behavior is required yet.

- [ ] **Step 4: Run Flutter analyze and test**

Run:

```bash
cd apps/mobile
flutter analyze
flutter test
```

Expected:

- Analyze passes.
- Default or updated widget test passes.

### Task 2: Define Domain Models And Parser Contract

**Files:**
- Create: `apps/mobile/lib/domain/item_type.dart`
- Create: `apps/mobile/lib/domain/record_status.dart`
- Create: `apps/mobile/lib/domain/extracted_item.dart`
- Create: `apps/mobile/lib/domain/parse_result.dart`
- Create: `apps/mobile/test/domain/parser_contract_test.dart`

- [ ] **Step 1: Define item types**

Create an enum with exactly:

```dart
enum ItemType {
  taskCreate,
  taskUpdate,
  shortTermState,
  lifeEvent,
  generalAnswer,
  profileCandidate,
}
```

Expected:

- No extra MVP item types.

- [ ] **Step 2: Define record status**

Create an enum with:

```dart
enum RecordStatus {
  pending,
  confirmed,
  edited,
  rejected,
  deleted,
  expired,
  archived,
}
```

Expected:

- All pending and official records can share consistent state language.

- [ ] **Step 3: Define extracted item fields**

Create an `ExtractedItem` model with these required concepts:

- local id
- raw input id
- type
- title
- content
- source text
- tags
- confidence
- need user confirm
- status
- created at
- updated at

Expected:

- `profile_candidate` and `task_create` can both live as pending extracted items before official write.

- [ ] **Step 4: Add parser contract tests**

Write tests for these sample inputs:

```text
明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。
```

Expected extracted item types:

- `taskCreate`
- `shortTermState`
- `profileCandidate`

Expected rule:

- `profileCandidate.needUserConfirm == true`
- `shortTermState` has an expiry concept.

- [ ] **Step 5: Run tests**

Run:

```bash
cd apps/mobile
flutter test test/domain/parser_contract_test.dart
```

Expected:

- Tests pass after model and mapping code exist.

### Task 3: Implement Local Database Schema

**Files:**
- Create: `apps/mobile/lib/data/local_db/app_database.dart`
- Create: `apps/mobile/lib/data/local_db/tables.dart`
- Create: `apps/mobile/test/data/local_db/app_database_test.dart`

- [ ] **Step 1: Define Drift tables**

Create tables for:

- `raw_inputs`
- `ai_parse_results`
- `extracted_items`
- `tasks`
- `short_term_states`
- `life_events`
- `profile_items`

Expected:

- Each official table keeps a reference to `source_raw_input_id` or `source_extracted_item_id` where useful.
- Each table includes `created_at`, `updated_at`, and `status` where useful.

- [ ] **Step 2: Generate Drift code**

Run:

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected:

- Generated Drift files compile.

- [ ] **Step 3: Add local database tests**

Test these flows:

1. Insert raw input.
2. Insert AI parse result.
3. Insert pending extracted item.
4. Confirm item into `tasks` or `profile_items`.
5. Mark pending item as `confirmed` or `edited`.
6. Mark a record as `deleted` and ensure it is excluded from active queries.

- [ ] **Step 4: Run database tests**

Run:

```bash
cd apps/mobile
flutter test test/data/local_db/app_database_test.dart
```

Expected:

- Local state flow works without any AI call.

### Task 4: Build API Proxy Schema Validation

**Files:**
- Create: `apps/api/src/schemas/parseResultSchema.ts`
- Create: `apps/api/src/routes/parse.ts`
- Create: `apps/api/src/server.ts`
- Create: `apps/api/test/parseResultSchema.test.ts`
- Modify: `apps/api/package.json`

- [ ] **Step 1: Define Zod schema**

Create a Zod schema that accepts only the 6 MVP item types:

```ts
const itemTypes = [
  "task_create",
  "task_update",
  "short_term_state",
  "life_event",
  "general_answer",
  "profile_candidate",
] as const;
```

Expected:

- Unknown item types fail validation.
- Each item requires `type`, `source_text`, `confidence`, and `need_user_confirm`.

- [ ] **Step 2: Add schema tests**

Test:

- Valid response with task/state/profile passes.
- Response with unknown type fails.
- Response missing `source_text` fails.
- Response with invalid confidence fails.

- [ ] **Step 3: Add `/parse` route**

Route input:

```json
{
  "text": "明天上午联系王总，我今天很累。",
  "timezone": "Asia/Shanghai"
}
```

Route output:

- Validated DeepSeek parse result on success.
- Structured error on validation failure.

- [ ] **Step 4: Add package scripts**

Add scripts:

```json
{
  "scripts": {
    "dev": "tsx src/server.ts",
    "test": "node --test --loader tsx test/*.test.ts",
    "typecheck": "tsc --noEmit"
  }
}
```

- [ ] **Step 5: Run API checks**

Run:

```bash
cd apps/api
npm run typecheck
npm test
```

Expected:

- TypeScript passes.
- Schema tests pass.

### Task 5: Implement DeepSeek Parser Service

**Files:**
- Create: `apps/api/src/services/deepseekParser.ts`
- Create: `apps/api/src/services/parserPrompt.ts`
- Modify: `apps/api/src/routes/parse.ts`
- Create: `apps/api/test/parserPrompt.test.ts`

- [ ] **Step 1: Create parser prompt**

Prompt must instruct DeepSeek:

- Output JSON only.
- Use only the 6 MVP item types.
- Do not turn one-time emotions into long-term profile.
- Preserve vague time text when exact date is uncertain.
- Mark `profile_candidate.need_user_confirm` as true.
- Include `source_text` for every item.

- [ ] **Step 2: Add prompt tests**

Assert prompt text contains these rules:

- `profile_candidate`
- `short_term_state`
- `JSON only`
- `source_text`
- `need_user_confirm`

- [ ] **Step 3: Implement DeepSeek call**

Use environment variables:

- `DEEPSEEK_API_KEY`
- `DEEPSEEK_BASE_URL`

Expected:

- If key is missing, return a clear server error.
- Do not log full user text by default.

- [ ] **Step 4: Add validation and retry**

Implement one retry when:

- JSON parsing fails.
- Zod validation fails.

Expected:

- On final failure, return a structured parse error instead of crashing.

- [ ] **Step 5: Run API checks**

Run:

```bash
cd apps/api
npm run typecheck
npm test
```

Expected:

- Parser prompt and schema tests pass.

### Task 6: Build Mobile Parser Client And Mock Mode

**Files:**
- Create: `apps/mobile/lib/data/parser/parser_client.dart`
- Create: `apps/mobile/lib/data/parser/mock_parser_client.dart`
- Create: `apps/mobile/lib/data/parser/http_parser_client.dart`
- Create: `apps/mobile/test/data/parser/parser_client_test.dart`

- [ ] **Step 1: Define parser client interface**

Methods:

- `parseInput(String text)`

Expected:

- UI can use mock parser before DeepSeek is connected.

- [ ] **Step 2: Implement mock parser**

For this input:

```text
明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。
```

Return three items:

- task create
- short-term state
- profile candidate

- [ ] **Step 3: Implement HTTP parser client**

Call the local API proxy `/parse` route.

Expected:

- Network errors return a user-friendly parse failure.
- Raw errors are not shown directly to users.

- [ ] **Step 4: Run parser client tests**

Run:

```bash
cd apps/mobile
flutter test test/data/parser/parser_client_test.dart
```

Expected:

- Mock parser returns stable contract objects.

### Task 7: Build Universal Input And Extracted Item Cards

**Files:**
- Create: `apps/mobile/lib/features/input/input_screen.dart`
- Create: `apps/mobile/lib/features/extracted_items/extracted_item_card.dart`
- Create: `apps/mobile/lib/features/extracted_items/extracted_items_controller.dart`
- Create: `apps/mobile/test/features/extracted_items/extracted_item_card_test.dart`

- [ ] **Step 1: Build input UI**

Screen contains:

- Text input.
- Submit button.
- Loading state.
- Error state.

Expected:

- User can submit natural language text.

- [ ] **Step 2: Persist raw input and AI parse result**

On submit:

1. Save `raw_inputs`.
2. Call parser client.
3. Save `ai_parse_results`.
4. Save pending `extracted_items`.

Expected:

- AI output is never written directly to official tables.

- [ ] **Step 3: Show extracted item cards**

Each card shows:

- Type label.
- Title/content.
- Source text.
- Tags.
- Confidence.
- Confirm / Edit / Reject buttons.

Expected:

- `profile_candidate` card clearly says it becomes long-term memory only after confirmation.

- [ ] **Step 4: Add card tests**

Test:

- Profile candidate shows confirmation warning.
- Short-term state shows expiry.
- Reject button exists.

- [ ] **Step 5: Run widget tests**

Run:

```bash
cd apps/mobile
flutter test test/features/extracted_items/extracted_item_card_test.dart
```

Expected:

- Cards render the safety-critical information.

### Task 8: Implement Confirm / Edit / Reject Flow

**Files:**
- Modify: `apps/mobile/lib/features/extracted_items/extracted_items_controller.dart`
- Create: `apps/mobile/lib/features/extracted_items/edit_extracted_item_sheet.dart`
- Create: `apps/mobile/test/features/extracted_items/confirmation_flow_test.dart`

- [ ] **Step 1: Confirm task item into `tasks`**

Expected:

- Confirmed task appears in `tasks`.
- Original extracted item status becomes `confirmed`.

- [ ] **Step 2: Confirm short-term state into `short_term_states`**

Expected:

- State has expiry.
- State appears in active state queries until expiry.

- [ ] **Step 3: Confirm profile candidate into `profile_items`**

Expected:

- Profile item only exists after user confirmation.
- Rejected profile candidate never affects suggestions.

- [ ] **Step 4: Edit before confirming**

Expected:

- Edited text is saved.
- Extracted item status becomes `edited`.
- Official record reflects the edited version.

- [ ] **Step 5: Reject item**

Expected:

- Extracted item status becomes `rejected`.
- No official record is created.

- [ ] **Step 6: Run confirmation flow tests**

Run:

```bash
cd apps/mobile
flutter test test/features/extracted_items/confirmation_flow_test.dart
```

Expected:

- State transitions are deterministic.

### Task 9: Build Home Suggestion MVP

**Files:**
- Create: `apps/mobile/lib/features/home/home_screen.dart`
- Create: `apps/mobile/lib/features/home/home_suggestion_service.dart`
- Create: `apps/mobile/test/features/home/home_suggestion_service_test.dart`

- [ ] **Step 1: Query suggestion inputs**

Use only:

- Today tasks.
- Overdue tasks.
- Next 7 days important tasks.
- Active short-term states.
- Confirmed profile items.

Expected:

- Deleted, rejected, pending, expired records do not affect suggestions.

- [ ] **Step 2: Implement rule-based suggestion service**

Rules:

- Prefer overdue or due-today tasks.
- If energy state is low, suggest a smaller or clearer task first.
- If reminder preference exists, avoid pushy language.
- Return 1-3 suggestions.

Expected:

- No vector retrieval required.
- No behavior pattern inference required.

- [ ] **Step 3: Render home screen**

Home shows:

- Current suggestion card.
- Today tasks.
- Active short-term states.
- Input entry point.

- [ ] **Step 4: Run home tests**

Run:

```bash
cd apps/mobile
flutter test test/features/home/home_suggestion_service_test.dart
```

Expected:

- Suggestion service respects task/state/profile boundaries.

### Task 10: Build Memory Management Views

**Files:**
- Create: `apps/mobile/lib/features/memory/memory_screen.dart`
- Create: `apps/mobile/lib/features/memory/profile_items_screen.dart`
- Create: `apps/mobile/lib/features/memory/short_term_states_screen.dart`
- Create: `apps/mobile/lib/features/memory/life_events_screen.dart`
- Create: `apps/mobile/test/features/memory/memory_management_test.dart`

- [ ] **Step 1: Add memory overview**

Show categories:

- Tasks.
- Short-term states.
- Life events.
- Profile items.

Expected:

- User can see what the system remembers.

- [ ] **Step 2: Add delete action**

Expected:

- Delete sets status to `deleted`.
- Deleted records do not appear in active suggestions.

- [ ] **Step 3: Add profile item edit action**

Expected:

- User can correct long-term profile wording.
- Updated profile still records source/updated time.

- [ ] **Step 4: Run memory tests**

Run:

```bash
cd apps/mobile
flutter test test/features/memory/memory_management_test.dart
```

Expected:

- User control over memory is verified.

### Task 11: Add Privacy And Failure Handling

**Files:**
- Create: `apps/mobile/lib/features/memory/privacy_screen.dart`
- Modify: `apps/api/src/services/deepseekParser.ts`
- Modify: `apps/api/src/server.ts`
- Create: `apps/api/test/privacyLogging.test.ts`

- [ ] **Step 1: Add privacy explanation screen**

Explain in plain language:

- Data is local-first.
- AI parsing sends the current input to the API proxy.
- User can delete remembered items.
- Long-term profile only takes effect after confirmation.

- [ ] **Step 2: Ensure backend does not log raw text by default**

Expected:

- Logs contain request id and error type.
- Logs do not contain full user input unless explicit debug mode is enabled locally.

- [ ] **Step 3: Handle parser failure in UI**

Expected user message:

```text
这次我没能稳定解析成可保存的数据。你可以重试，或者先手动记录。
```

- [ ] **Step 4: Run privacy/failure tests**

Run:

```bash
cd apps/api
npm test
cd ../mobile
flutter test
```

Expected:

- Parser failures do not crash App.
- Raw text is not logged by default.

### Task 12: Android And iOS Smoke Verification

**Files:**
- Verify: `apps/mobile/android/`
- Verify: `apps/mobile/ios/`
- Create: `docs/architecture/mobile-smoke-test.md`

- [ ] **Step 1: Run Android simulator smoke test**

Run:

```bash
cd apps/mobile
flutter run -d android
```

Expected:

- App launches.
- User can submit mock input.
- Extracted item cards appear.
- Confirmed records appear on home.

- [ ] **Step 2: Run iOS simulator smoke test**

Run:

```bash
cd apps/mobile
flutter run -d ios
```

Expected:

- App launches on iOS simulator.
- Same MVP flow works.

- [ ] **Step 3: Document smoke test results**

Create `docs/architecture/mobile-smoke-test.md` with:

```markdown
# Mobile Smoke Test

## Android

- Device:
- Date:
- Result:
- Notes:

## iOS

- Device:
- Date:
- Result:
- Notes:
```

Expected:

- Cross-platform readiness is visible to future agents.

## 6. Acceptance Criteria

MVP is acceptable when this exact scenario works end-to-end:

Input:

```text
明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。
```

Expected:

1. App saves original input to `raw_inputs`.
2. Parser returns three extracted items:
   - `task_create`
   - `short_term_state`
   - `profile_candidate`
3. App stores the parser result in `ai_parse_results`.
4. App stores all three pending items in `extracted_items`.
5. User confirms the task.
6. User confirms the short-term state or sees it as visible auto-recorded state.
7. User confirms the profile candidate before it becomes active long-term memory.
8. Home suggestion uses the task, active short-term state, and confirmed profile item.
9. User can delete the profile item and it stops affecting suggestions.
10. The flow runs on Android and iOS.

## 7. Self-Review Notes

- Scope is intentionally limited to six item types.
- Long-term profile exists in MVP only as user-confirmed `profile_items`; automatic profile evolution is excluded.
- Vector retrieval, cloud sync, CRM, health analytics, subscriptions, and voice features are explicitly excluded.
- The plan separates AI guesses (`extracted_items`) from user-confirmed truth (`tasks`, `short_term_states`, `life_events`, `profile_items`).
- The API key is kept out of the mobile client through a minimal backend proxy.
