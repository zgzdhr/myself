---

# AI Personal Memory Action System：MVP 下一阶段任务地图

## 0. 当前共识更新

本项目已经不是空项目，`main` 分支已经包含 Flutter App、API proxy、本地数据库、Mock Parser、HTTP Parser、确认卡片、首页建议等 MVP 骨架。

下一阶段目标不是扩大功能，而是：

1. 先把本地工作区同步到远端 `main` 的真实主线状态；
2. 同步文档和代码现状；
3. 跑通并验证当前闭环；
4. 修正自动写入策略；
5. 补齐任务更新、普通问答、记忆管理；
6. 再考虑小总结和上下文组装；
7. 暂不做完整 Agent、向量检索、行为模式推断。

---

# 1. 关于 7 张 MVP 表是否足够

当前 7 张表是：

```text
raw_inputs
ai_parse_results
extracted_items
tasks
short_term_states
life_events
profile_items
```

我的判断是：

> **这 7 张表作为 MVP 第一阶段基本够用，但不是长期够用。**

它们能支撑：

* 原始输入保存；
* AI 解析结果保存；
* 待确认条目保存；
* 正式任务保存；
* 短期状态保存；
* 生活事件保存；
* 长期画像保存。

但是如果你接受“短期任务 / 短期状态可以自动入库”，我建议后续至少补两个表，或者在现有表里补等价字段。

## 1.1 建议后续新增：`user_preferences` 或 `app_settings`

用途：保存用户对自动写入的偏好。

例如：

```text
auto_save_today_tasks: true
auto_save_short_term_states: true
auto_save_life_events: false
require_confirmation_for_profile: true
default_task_confirm_mode: auto_with_undo
```

为什么需要它？

因为不同用户接受程度不一样。有些人希望 AI 自动整理，有些人希望每条都确认。

所以建议产品后期给用户三种模式：

```text
谨慎模式：所有任务和记忆都需确认
平衡模式：今日任务、短期状态自动保存，长期画像需确认
高效模式：明确任务自动保存，敏感/长期内容确认
```

MVP 可以先写死成“平衡模式”。

## 1.2 建议后续新增：`record_actions` 或 `activity_log`

用途：记录系统做过什么。

例如：

```text
AI 自动创建了一个今日任务
用户撤销了这条任务
用户确认了长期画像
用户删除了短期状态
AI 解析失败
```

这个表不是为了复杂审计，而是为了以后支持：

* 撤销；
* 解释；
* 回滚；
* 用户信任；
* 调试 AI 错误。

MVP 初期可以不加，但我建议在任务规划里留下位置。

## 1.3 当前结论

短期内：

> **先保留 7 张核心表，不要现在大改数据库。**

但文档里要补一句：

```md
The current 7 MVP tables are enough for the first controlled loop. Later stages may add `user_preferences` and `record_actions` to support auto-save modes, undo, and better auditability.
```

---

# 2. 自动写入策略：重新确认

你说得对，不能所有东西都让用户点确认。否则用户随口说一句“今天要联系王总”，还要再点一下确认，体验会很烦。

我建议改成三层策略。

## 2.1 必须确认

这些内容必须确认：

```text
长期画像 profile_candidate
任务删除
任务取消
任务延期到具体时间
任务改期到具体时间
修改已有任务
健康信息长期保存
行为模式总结
任何会长期影响建议的内容
```

原因：这些内容会长期影响系统对用户的理解，或者会改变已有数据，风险更高。

## 2.2 可以自动入库，但必须可见、可撤销

这些内容可以自动入库：

```text
今日任务
明确的短期任务
短期状态
低风险生活事件
用户明确说“记一下”的普通经验
```

例如用户说：

```text
今天上午联系王总，我现在有点累。
```

系统可以直接生成：

```text
今日任务：联系王总
短期状态：今天有点累
```

但首页或输入结果区必须提示：

```text
我已帮你整理为：
- 今日任务：联系王总
- 短期状态：今天有点累

你可以撤销或修改。
```

也就是说，这不是“悄悄写入”，而是：

> **自动写入 + 明确展示 + 随时撤销。**

## 2.3 默认不保存

这些默认不保存：

```text
普通问答
闲聊
一次性情绪吐槽
不明确的信息
没有后续价值的碎片
```

例如：

```text
Flutter 是什么？
```

应该只回答，不进入记忆。

---

# 3. 关于向量检索和行为模式推断

新的共识：

```md
MVP 不做向量检索，不做行为模式推断。

首页建议先使用：
- 今日任务
- 逾期任务
- 未来 7 天任务
- 未过期短期状态
- 已确认长期画像

如果真实测试中建议效果明显不够，再考虑增加：
- 标签检索
- 简单关键词检索
- 小总结
- 向量检索
- 行为模式候选
```

这里要特别写清楚：

> **不是永远不做，而是 MVP 先不做。**

---

# 4. Codex 任务拆分总览

不要给 Codex 一条大任务。应该分成小任务，每个任务只解决一个问题。

下面是我建议的长期任务顺序。

## Task 0：把本地 main 同步到远端 main

### 目标

让本地工作区进入和远端 `main` 一致的真实主线状态，避免后续任务在旧本地主线或错误分支上执行。

### 推荐模型

```text
模型：5.4 Mini
推理强度：低
```

### 原因

这是分支状态校准任务，不需要强模型。

### 给 Codex 的任务

```md
# Task 0: Sync local main to remote main

Please inspect the current `main` and `origin/main` branches first.

If local `main` is behind `origin/main`, fast-forward or reset the local branch to match the remote mainline.

Do not create new app code in this task.

After syncing, verify:
- `git status --short --branch`
- `git log --graph --decorate --oneline --all -10`

If the local checkout has unrelated untracked files, leave them alone unless they block the branch sync.
```

## Task 1：同步 README 和 AGENTS.md 当前状态

### 目标

让文档反映当前真实代码状态，避免 Codex 重复创建项目骨架。

### 推荐模型

```text
模型：5.4 Mini
推理强度：低 / 中
```

### 原因

这是文档同步任务，不需要最强模型。

### 给 Codex 的任务

```md
# Task 1: Sync README and AGENTS.md with current implementation status

Please inspect the current `main` branch first.

The project already includes:
- Flutter mobile app
- TypeScript API proxy
- Riverpod app shell
- Drift / SQLite schema
- parser domain models
- mock parser
- HTTP parser client
- universal input screen
- extracted item cards
- confirm / edit / reject flow
- basic home suggestion service
- API Zod schema
- DeepSeek parser service
- privacy logging test

Do not recreate `apps/mobile` or `apps/api`.

Update:
- `README.md`
- `AGENTS.md`

Make them say that the project is now in MVP skeleton stabilization stage, not pre-development planning stage.

Also add a section about the updated auto-save policy:
- Long-term profile must always require user confirmation.
- Today tasks and short-term states may be auto-saved if clearly extracted, but they must be visible, editable, deletable, and undoable.
- Vector search and behavior pattern inference are postponed until MVP testing shows they are needed.

Do not change app functionality in this task.
```

## Task 2：创建当前验证文档并跑测试

### 目标

确认当前项目到底能不能跑。

### 推荐模型

```text
模型：5.4 Mini
推理强度：低
```

### 原因

这是检查、记录、修小问题。除非报错复杂，否则不用 5.5。

### 给 Codex 的任务

```md
# Task 2: Run current verification and document results

Create:

`docs/architecture/current-verification.md`

Run and document:

```bash
cd apps/mobile
flutter analyze
flutter test

cd ../api
npm run typecheck
npm test
```

If any test fails, fix only minimal issues required to make existing intended behavior pass.

Do not add new features.

The verification document should include:

* date
* command
* result
* notes
* unresolved problems
```

## Task 3：调整自动写入策略

### 目标

把“短期任务 / 今日任务 / 短期状态可以自动保存”的产品策略落到文档和代码边界里。

### 推荐模型

```text
模型：5.5
推理强度：中
```

### 原因

这里涉及产品逻辑、数据状态、用户体验，最好用 5.5。

### 给 Codex 的任务

```md
# Task 3: Implement MVP auto-save policy for short-term records

Current rule update:

Long-term profile candidates must still require confirmation before becoming active profile items.

However, clearly extracted short-term records may be auto-saved:

- `task_create` when it is clearly a today / near-term task
- `short_term_state` when it describes current or recent temporary state
- low-risk `life_event` only when user explicitly says to remember it

The auto-save behavior must be visible and reversible.

Implement a controlled MVP policy:

1. Add clear code-level comments or constants for save policy.
2. Keep `profile_candidate` confirmation required.
3. Allow `short_term_state` to be saved automatically into `short_term_states`.
4. Allow clear today/near-term `task_create` to be saved automatically into `tasks`, if the policy is enabled.
5. Show auto-saved items in the UI with an indication like:
   “已自动整理，可修改或撤销”
6. Add tests proving:
   - profile candidate is not auto-confirmed
   - short-term state can be auto-saved
   - today task can be auto-saved
   - auto-saved records can be deleted or undone
   - deleted auto-saved records do not affect suggestions

Do not add vector search.
Do not add behavior pattern inference.
Do not add autonomous agents.
```

### 这里需要你和 Codex 再确认的点

这个任务可能会引出一个产品选择：

```text
自动写入后，extracted_items 的状态是 confirmed，还是 auto_confirmed？
```

我建议新增一个状态：

```text
auto_confirmed
```

但这会改 enum 和数据库逻辑。为了 MVP 简单，也可以先用：

```text
confirmed + metadata/source = auto
```

如果要更严谨，后续再加 `confirmation_method` 字段：

```text
manual
auto
edited
```

## Task 4：修正 ParserClient 里的 rawInputId 归属

### 目标

让 ID 责任更清楚。

### 推荐模型

```text
模型：5.4
推理强度：中
```

### 原因

这是中等复杂度重构，不一定要 5.5。

### 给 Codex 的任务

```md
# Task 4: Clean up rawInputId ownership in parser flow

Currently, rawInputId is generated both around the controller flow and inside parser result mapping.

Refactor so that:

- `ExtractedItemsController` owns raw input creation and rawInputId.
- `ParserClient` only parses text and returns AI result data.
- Parser result mapping should not create or own the final rawInputId.
- The persistence layer binds extracted items to the rawInputId created by the controller.

Keep behavior unchanged.

Add or update tests to prove:
- raw_inputs row id matches extracted_items.raw_input_id
- ai_parse_results.raw_input_id matches raw_inputs.id
- parser client does not decide final persistence id
```

## Task 5：把 general_answer 从保存卡片中分离

### 目标

普通问答不应该变成“待确认记忆”。

### 推荐模型

```text
模型：5.4
推理强度：中
```

### 原因

涉及 UI 和数据流，但不算特别难。

### 给 Codex 的任务

```md
# Task 5: Separate general_answer from saveable extracted item cards

Current issue:

`general_answer` is one of the six MVP item types, but it should not behave like a saveable memory card by default.

Implement:

1. If parse result contains only `general_answer`, show `user_reply` as normal assistant response.
2. Do not show confirm/edit/reject cards for pure `general_answer`.
3. Do not write `general_answer` into official memory tables by default.
4. If a parse result contains both answer and saveable items, show:
   - assistant reply
   - saveable extracted item cards
5. Add tests for:
   - pure general answer creates no pending save card
   - mixed result still shows saveable cards
   - general answer does not affect home suggestions

Do not remove `general_answer` from the schema.
```

## Task 6：实现 task_update 的最小闭环

### 目标

让用户可以自然语言更新任务。

### 推荐模型

```text
模型：5.5
推理强度：高
```

### 原因

这是当前最复杂的 MVP 功能之一。它涉及任务匹配、模糊性、确认流程、错误处理。

### 给 Codex 的任务

```md
# Task 6: Implement minimal task_update flow

Goal:

Support simple task updates without building a complex autonomous agent.

Examples:

- “把联系王总改到后天”
- “联系王总已经完成了”
- “那个客户资料不用做了”
- “把准备方案延期到明天上午”

MVP behavior:

1. Parser may return `task_update`.
2. `task_update` item should include:
   - source_text
   - target_task_title or target_text
   - update_action: complete | cancel | delay | edit
   - due_time_text / due_time_iso when relevant
   - confidence
   - need_user_confirm

3. App should try simple matching against active tasks:
   - exact title match first
   - simple contains match second
   - if exactly one match, show update confirmation card
   - if multiple matches, show “请选择要更新的任务”
   - if no match, show “没找到对应任务”

4. Do not automatically update existing tasks without user confirmation in MVP.

5. Add tests:
   - complete matched task
   - delay matched task
   - cancel matched task
   - ambiguous match requires selection
   - no match creates no official change
```

注意这里我建议：

> `task_update` 不要自动生效。
> 因为它会修改已有任务，风险比新建今日任务更高。

## Task 7：完善记忆管理页面

### 目标

用户能看到 AI 记住了什么，并能删除 / 修改。

### 推荐模型

```text
模型：5.4
推理强度：中
```

### 原因

主要是 UI + 数据查询 + 删除逻辑。

### 给 Codex 的任务

```md
# Task 7: Improve memory management screens

Goal:

Users must be able to see, edit, and delete what the app remembers.

Build minimal screens for:

- Tasks
- Short-term states
- Life events
- Profile items

Requirements:

1. Keep the existing memory overview screen.
2. Show counts by category.
3. Show active records.
4. Allow deleting records by setting status = deleted.
5. Allow editing profile item content.
6. Show source text or source summary when available.
7. Deleted records must not affect home suggestions.
8. Add widget or controller tests.

Do not add cloud sync.
Do not add vector search.
Do not add behavior-pattern inference.
```

## Task 8：DeepSeek 真实解析 smoke test

### 目标

确认当前 DeepSeek API、模型名、JSON schema、response_format 能不能真实跑。

### 推荐模型

```text
模型：5.4 Mini
推理强度：低 / 中
```

### 原因

主要是运行和记录。如果报错复杂，再切 5.4。

### 给 Codex 的任务

````md
# Task 8: Verify real DeepSeek parse smoke test

Goal:

Confirm that the API proxy can call DeepSeek and return valid schema output.

Steps:

1. Check `.env.example`.
2. Do not commit real API keys.
3. Reuse the existing smoke parse command and sample set if present; otherwise create the smallest possible equivalent.
4. Run the smoke parse command using sample input:

```text
明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。
````

Expected result:

* task_create
* short_term_state
* profile_candidate

5. Verify:

   * model name is accepted
   * response_format is accepted
   * thinking disabled option is accepted or removed if unsupported
   * returned JSON passes Zod schema
   * raw user text is not logged by default

6. Document results in:

`docs/architecture/deepseek-smoke-test.md`

If the configured model name does not work, update `.env.example` with a known working model name and explain why.
````

## Task 9：Android / iOS smoke test

### 目标

确认 App 在模拟器能打开，能跑 mock parser 流程。

### 推荐模型

```text
模型：5.4 Mini
推理强度：低
```

### 原因

运行验证任务，不需要强模型。

### 给 Codex 的任务

````md
# Task 9: Android and iOS smoke verification

Goal:

Verify the current Flutter app launches on Android and iOS.

Use mock parser mode first.

Run:

```bash
cd apps/mobile
flutter run -d android --dart-define=PARSER_MODE=mock
flutter run -d ios --dart-define=PARSER_MODE=mock
````

Document results in:

`docs/architecture/mobile-smoke-test.md`

Smoke scenario:

1. App launches.
2. User enters:
   “明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。”
3. App shows parsed items.
4. User confirms or auto-saves allowed short-term items.
5. Home suggestion updates.
6. Memory entry count updates.

Do not implement new features unless needed to fix launch/runtime errors.
````

## Task 10：小总结机制设计，不急着实现

### 目标

只设计，不先写复杂代码。

### 推荐模型

```text
模型：5.5
推理强度：中 / 高
```

### 原因

总结机制是产品核心之一，设计要谨慎。可以先让 Codex 做技术方案，不要直接实现。

### 给 Codex 的任务

```md
# Task 10: Design small summary mechanism, do not implement yet

Goal:

Design the future small summary mechanism inspired by conversation-summary systems, but adapted for this personal memory/action app.

Do not implement code yet.

Please create:

`docs/architecture/summary-system-design.md`

Cover:

1. What should be summarized:
   - recent raw inputs
   - today records
   - weekly records
   - theme-specific life events
   - repeated short-term states
2. What should not be summarized:
   - sensitive data without user control
   - deleted records
   - rejected extracted items
3. Summary types:
   - daily_summary
   - recent_input_summary
   - weekly_review_summary
   - profile_candidate_summary
4. Relationship with existing tables.
5. Whether new tables are needed later:
   - summaries
   - summary_sources
6. How summaries enter prompt context.
7. How users can view/delete summaries.
8. How to avoid creating long-term profile from one-time events.

Important:
- Do not add vector search in MVP.
- Do not add behavior pattern inference yet.
- Do not implement autonomous agents.
```

## Task 11：上下文组装器设计

### 目标

为以后“基于记忆回答”打基础。

### 推荐模型

```text
模型：5.5
推理强度：高
```

### 原因

这是架构层任务，涉及未来 Agent 化路线。

### 给 Codex 的任务

```md
# Task 11: Design context builder for memory-based assistant replies

Goal:

Design a controlled context builder, not an autonomous agent.

Create:

`docs/architecture/context-builder-design.md`

MVP context builder should use only:

- current user input
- today tasks
- overdue tasks
- next 7 days tasks
- active short-term states
- confirmed profile items
- optionally recent life events by simple tags

Do not use vector search yet.

Design:

1. Context selection rules by user intent:
   - current suggestion
   - daily review
   - general answer
   - task planning
   - life event reflection
2. Which tables are queried.
3. Which statuses are excluded:
   - pending
   - rejected
   - deleted
   - expired
4. Maximum context size.
5. How to explain why a suggestion was made.
6. Future upgrade path:
   - keyword/tag search
   - summaries
   - vector search
   - LLM rerank

Do not implement code in this task unless explicitly asked.
```

---

# 5. 模型和推理强度总表

| 任务      | 内容                     | 推荐模型     | 推理强度 |
| ------- | ---------------------- | -------- | ---- |
| Task 0  | 同步本地 main 到远端 main     | 5.4 Mini | 低    |
| Task 1  | 同步 README / AGENTS     | 5.4 Mini | 低/中  |
| Task 2  | 跑测试并记录                 | 5.4 Mini | 低    |
| Task 3  | 自动写入策略                 | 5.5      | 中    |
| Task 4  | rawInputId 重构          | 5.4      | 中    |
| Task 5  | general_answer 分离      | 5.4      | 中    |
| Task 6  | task_update 最小闭环       | 5.5      | 高    |
| Task 7  | 记忆管理页面                 | 5.4      | 中    |
| Task 8  | DeepSeek smoke test    | 5.4 Mini | 低/中  |
| Task 9  | Android/iOS smoke test | 5.4 Mini | 低    |
| Task 10 | 小总结机制设计                | 5.5      | 中/高  |
| Task 11 | 上下文组装器设计               | 5.5      | 高    |

---

# 6. Plus 额度下的推荐执行顺序

你是 Plus 会员，Codex 额度要省着用，所以我建议这样排：

## 第一批：低成本稳定项目

先用 5.4 Mini 做：

```text
Task 0：同步本地 main
Task 1：同步文档
Task 2：跑测试
Task 8：DeepSeek smoke test
Task 9：移动端 smoke test
```

这几个任务不用烧 5.5。

## 第二批：中等代码功能

再用 5.4 做：

```text
Task 4：rawInputId 重构
Task 5：general_answer 分离
Task 7：记忆管理页面
```

这几个是代码任务，但复杂度中等。

## 第三批：高价值复杂任务

最后用 5.5 做：

```text
Task 3：自动写入策略
Task 6：task_update 最小闭环
Task 10：小总结机制设计
Task 11：上下文组装器设计
```

这里最应该花额度的是：

1. **Task 3 自动写入策略**
2. **Task 6 task_update**
3. **Task 11 上下文组装器**

因为这三个会决定产品未来会不会乱。

---

# 7. 我建议现在先执行哪一个？

我建议你现在先让 Codex 做：

```text
Task 0：同步本地 main 到远端 main
```

原因是这一步最小、最安全，而且能把你刚刚修正的几个关键共识写进项目：

1. 长期画像必须确认；
2. 今日任务和短期状态可以自动写入，但必须可见、可删、可撤销；
3. 向量检索和行为模式推断 MVP 不做，效果不好再补；
4. 当前项目已经有代码骨架，不要重复创建；
5. 后续任务要分阶段做，不要一口气做大 Agent。

这一步做完以后，Codex 后续就不容易跑偏。
