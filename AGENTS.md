# AI 个人记忆与行动整理系统：项目协作记忆

## 项目定位

本项目不是普通 To-do List，也不是“大而全 AI 管家”。

更准确的定义是：

> 一个面向 Android 与 iOS 的个人记忆与行动整理 App。用户用自然语言输入任务、状态、经历、偏好和问题，系统用 AI 解析为结构化数据，经用户确认后写入本地记忆，并在后续建议、复盘和回复中调用这些记忆。

产品灵魂是：

> 这句话对用户未来有没有价值？如果有，应该保存到哪里、保存多久、什么时候再次拿出来用？

## 当前规划状态

截至 2026-06-18，项目已经从早期 0-6 阶段的 MVP 建设路线，经过 **Phase 4：真实试用信任修复阶段**，进入 **Phase 5：账号云端化、每日复盘与设置完善阶段**。Flutter App、API proxy、本地数据库、解析链路、基础确认流程、记忆管理页面、移动端 smoke、真实 Android APK + DeepSeek API proxy 试用、`current_suggestion` / `task_update_resolution` ContextBuilder、解释性 UI、中文语义边界校准、Phase 3 真实试用反馈整理、Phase 4A-4E 信任修复都已经完成。

Phase 4A 已完成并提交：保留最近 3 批 pending 待确认内容、删除操作二次确认、Debug 日期切换能力。Phase 4B 已完成并提交：时间上下文传给 DeepSeek、可选地点上下文合同、同日隐含时间语义、今天 / 明天 / 未来 / 未安排任务过滤、任务时间展示和日期时间编辑器。Phase 4C 已完成：取消类表达、任务匹配噪声清洗和真实失败样例覆盖。Phase 4D 已完成：首页 AI 建议和今日行动可展开，建议依据按任务、当前状态、长期偏好分组展示。Phase 4D.5 已完成：新增 `task_status: active / completed / cancelled`，完成/取消任务保持可见但不参与建议和任务更新匹配。Phase 4E 已完成：Android debug APK + 本地 API proxy + DeepSeek 真实试用链路文档和构建验证。Phase 5 前置 A/B/C 已完成第一轮：AI 文字解析准确性增强、本地任务提醒、底部四栏导航、复盘入口骨架和“我的 / 设置”页面骨架。Phase 5A 账号与云端数据已完成第一版：Supabase Flutter 接入、邮箱 OTP 登录骨架、退出登录、云端 schema/RLS 草案和数据边界文档。当前下一步是 **每日复盘 `/review`**。不要回头重复做 Phase 3 D0/D1/D2，也不要继续按旧的“Phase 4 首页建议 / Phase 5 记忆管理 / Phase 6 双端验证”路线理解当前项目。

Phase 5 的长期方向仍可以包括电脑端分析界面、受控知识库和可控自进化，但这些不是近期任务。根据 2026-06-18 的最新决策，学习目标、学习进展和学习卡点全部后置；当前先把 App 做成可以直接使用的成品。账号登录和云端数据已完成第一版，接下来做每日复盘和复盘轻量服务每日任务建议。

当前架构判断：

- 项目不是屎山，复杂度主要来自个人记忆 App 必要的信任边界。
- 当前最大架构压力是 `/parse` 结构化解析链路承载了太多“智能”期待。
- `/parse` 应继续负责结构化入库，不应继续塞复盘、学习教练、知识库分析和自进化逻辑。
- 后续建议拆分 AI 能力：`/parse` 负责结构化入库，`/review` 负责复盘总结和任务处理建议，`/memory` 负责记忆查看、编辑、删除、恢复和来源解释。`/coach` 暂不作为近期实现入口。
- 电脑端适合作为后续分析界面：手机端负责快速语音/文本输入和确认，电脑端未来可以看详细复盘和来源依据。知识库后置，当前不要把它作为近期主线。
- 自进化在本项目里不是“AI 自动替用户进化”，而是用户确认过的偏好、事件、任务和总结持续沉淀，让后续建议越来越贴近用户。

已确认的核心链路：

```text
万能输入框
→ DeepSeek 解析 JSON
→ schema 校验
→ 生成 extracted items
→ 用户确认 / 修改 / 拒绝
→ 写入本地数据库
→ ContextBuilder 选择 current_suggestion / task_update_resolution 所需上下文
→ 首页基于今日任务、短期状态、已确认长期画像给简单建议
```

当前已经落地的代码能力：

- `apps/mobile`：Flutter Android/iOS App 骨架。
- `apps/mobile/lib/app/app_shell.dart`：Riverpod App Shell、底部四栏导航和页面入口。
- `apps/mobile/lib/features/input/input_screen.dart`：万能输入页。
- `apps/mobile/lib/features/extracted_items/`：待确认卡片、编辑弹层、确认 / 修改 / 拒绝控制器。
- `apps/mobile/lib/features/home/`：首页 UI 和基础建议服务。
- `apps/mobile/lib/features/review/review_screen.dart`：每日复盘入口骨架，真实 `/review` 尚未接入。
- `apps/mobile/lib/features/settings/profile_settings_screen.dart`：“我的 / 设置”页面骨架，包含账号、同步、提醒、复盘、AI、隐私和 App 状态入口。
- `apps/mobile/lib/features/account/`：Supabase 账号初始化、邮箱 OTP 登录抽象和未配置兜底。
- `apps/mobile/lib/features/context/context_builder.dart`：受控 ContextBuilder，目前支持 `current_suggestion` 和 `task_update_resolution`。
- `apps/mobile/lib/features/memory/`：记忆入口、隐私页、短期状态 / 生活事件 / 长期画像页面。
- `apps/mobile/lib/data/local_db/`：Drift / SQLite schema 和本地数据库访问。
- `apps/mobile/lib/data/parser/`：Mock Parser、HTTP Parser Client、ParserClient 抽象。
- `apps/mobile/lib/domain/`：解析结果、结构化条目、类型和状态模型。
- `apps/api`：TypeScript API proxy。
- `apps/api/src/routes/parse.ts`：`POST /parse` 接口。
- `apps/api/src/schemas/parseResultSchema.ts`：AI 返回 JSON 的 Zod schema。
- `apps/api/src/services/deepseekParser.ts`：DeepSeek 调用与解析服务。
- `apps/api/src/services/parserPrompt.ts`：结构化解析 prompt。
- `apps/api/scripts/smokeParseSamples.ts`：真实解析 smoke 脚本。
- `2026-06-07-phase3_d0.md`：Phase 3 D0 中文语义边界校准指导文件。
- `docs/architecture/chinese-semantic-classification-rules.md`：D0 中文语义分类规则文档。
- `apps/mobile/lib/features/memory/delete_confirmation.dart`：Phase 4A 删除确认弹窗复用入口。
- `apps/mobile/lib/features/home/home_screen.dart`：首页、Debug 日期切换、当前时间 provider 入口。
- `apps/mobile/lib/features/memory/task_time_formatter.dart`：Phase 4B 任务时间展示规则。

当前已经落地的验证资产：

- `apps/mobile/test/`：移动端数据库、parser contract、确认流、首页建议、记忆管理和 widget 测试。
- `apps/mobile/test/features/context/context_builder_test.dart`：`current_suggestion` / `task_update_resolution` ContextBuilder 的边界测试。
- `apps/api/test/`：API schema、DeepSeek parser、prompt、sample set、隐私日志和 smoke 脚本测试。
- `docs/architecture/phase-2-ai-parse-smoke.md`：真实 DeepSeek 解析 smoke 说明。
- `docs/architecture/mobile-smoke-test.md`：移动端 smoke 验证记录。
- `docs/architecture/summary-system-design.md`：Task 10 小总结机制设计。
- `docs/architecture/context-builder-design.md`：Task 11 受控 Context Builder 设计。
- `docs/architecture/phase-5-task-map.md`：Phase 5 中文任务地图，记录当前建议执行顺序。
- `docs/architecture/phase-5a-account-cloud-data.md`：Phase 5A 账号和云端数据边界。
- `docs/architecture/supabase/phase-5a-schema.sql`：Supabase 表结构和 RLS 草案。
- `docs/architecture/phase-5-reflection-goals-evolution.md`：Phase 5 复盘、目标对齐、电脑端和自进化长期路线。
- `docs/architecture/current-verification.md`：当前自动化验证结果。
- `docs/architecture/phase-3-verification.md`：Phase 3 验收和真实试用结论。
- `docs/architecture/phase-3-real-trial-feedback.md`：三星 Android 真机真实试用反馈。
- `2026-06-05-mvp-next-task-map.md`：当前 Phase 4 任务地图。

重要源文档：

- `README.md`：项目入口说明。
- `AI_personal_memory_action_system_design_v0.2.md`：ChatGPT 生成的产品与系统设计讨论稿。
- `docs/superpowers/plans/2026-05-31-personal-memory-action-system-mvp.md`：Codex 整理的 MVP 开发实施计划。
- `docs/architecture/summary-system-design.md`：未来 summary / compressed context 的边界。
- `docs/architecture/context-builder-design.md`：未来 Context Builder 的整体设计。

新窗口 / 新 session 建议阅读顺序：

1. `AGENTS.md`：先了解当前项目状态、边界和协作规则。
2. `README.md`：快速看项目入口、目录和当前能力。
3. `docs/architecture/current-verification.md`：确认最近一次自动化验证状态。
4. `docs/architecture/mobile-smoke-test.md`：确认 Android / iOS smoke 状态。
5. `docs/architecture/phase-2-ai-parse-smoke.md`：确认真实 DeepSeek parse smoke 流程。
6. `docs/architecture/phase-3-verification.md`：确认 Phase 3 已收尾到真实试用，并了解哪些问题进入 Phase 4。
7. `docs/architecture/phase-3-real-trial-feedback.md`：查看三星 Android 真机反馈原始整理。
8. `2026-06-05-mvp-next-task-map.md`：确认当前 Phase 4A/4B/4C/4D/4E 任务地图。
9. `docs/architecture/chinese-semantic-classification-rules.md`：查看 D0 正式语义规则。
10. `docs/architecture/task-update-resolution.md`：理解 `task_update` 匹配和后续增强边界。
11. `docs/architecture/phase-5-task-map.md`：先看 Phase 5 当前中文任务地图和执行顺序。
12. `docs/architecture/phase-5-reflection-goals-evolution.md`：长期路线背景；注意其中学习目标 / 卡点路线已后置。
13. `docs/architecture/context-builder-design.md`：理解 Context Builder 总设计。
14. `apps/mobile/lib/features/context/context_builder.dart`：看当前已实现的 `current_suggestion` / `task_update_resolution` ContextBuilder。
15. `apps/mobile/lib/features/home/home_suggestion_service.dart`：看首页建议如何复用 ContextBuilder。
16. `apps/mobile/test/features/context/context_builder_test.dart`：看当前 ContextBuilder 的测试边界。

## 目标平台与技术方向

本项目当前工程明确面向两个移动端版本：

- Android App
- iOS App

建议优先使用 Flutter 开发一套跨平台移动端代码，同时支持 Android 与 iOS。

长期可能补充电脑端 / Web 分析界面。电脑端不应抢在 Phase 5 小闭环之前做成完整第二客户端；它更适合作为后续的复盘、目标、进展、知识库和来源依据阅读界面。

MVP 推荐技术方向：

- 移动端：Flutter。
- 本地数据库：SQLite，推荐 Drift 作为 Flutter 侧数据库层。
- 状态管理：优先 Riverpod，避免一开始做复杂架构。
- 后端：最小 Node.js / TypeScript API proxy，只负责转发 DeepSeek 请求和保护 API Key。
- AI：DeepSeek，输出结构化 JSON。
- 数据策略：当前仍是本地 SQLite；下一阶段转向账号登录和云端数据，手机端保留缓存 / 迁移源 / 离线兜底。

## MVP 范围

MVP 的定义是：

> 自然语言结构化入库 + 短期状态 + 最小长期画像 + 简单行动建议。

第一版要验证的问题不是“能不能做完整 AI 管家”，而是：

> 用户是否愿意把脑子里的事情说给 App，并接受它帮自己整理成可确认、可修改、可删除的数据。

MVP 必做：

1. 万能输入框。
2. DeepSeek 解析自然语言为 JSON。
3. schema 校验、失败兜底、解析错误记录。
4. extracted items 确认卡片。
5. 用户确认 / 修改 / 拒绝流程。
6. 本地数据库保存正式记录。
7. 今日任务、短期状态、最小长期画像。
8. 首页简单建议。
9. 用户可查看和删除 AI 记住的内容。

MVP 暂不做：

- 行为模式自动总结。
- 自动画像自进化。
- 向量检索。
- 自动 summary 生成。
- 复杂 Context Builder intent。
- 复杂复盘模块。
- 健康趋势分析。
- CRM / 项目管理。
- 云同步。
- 自建语音识别。
- 语音回复。
- 商业化订阅。

## MVP 支持的信息类型

第一版支持 6 类输入结果：

1. `task_create`：新建任务。
2. `task_update`：更新任务，包括完成、取消、延期、修改时间。
3. `short_term_state`：短期状态，例如今天很累、最近睡眠不好、现在在路上。
4. `life_event`：生活事件 / 经验记录，例如今天做菜糖放多了、今天客户沟通不舒服。
5. `general_answer`：普通问答，不默认保存。
6. `profile_candidate`：长期画像候选，例如不喜欢频繁提醒、一般晚上效率高、经常出差。

关键原则：

- `short_term_state` 可以自动记录，但必须可见、可删，并有有效期。
- `profile_candidate` 必须用户确认后才能写入正式 `profile_items` 并生效。
- AI 自动推断的长期画像不能直接生效。
- 单次情绪表达不能直接进入长期画像。
- 单次失败或延期不能直接形成行为模式。

## 自动写入策略

MVP 现在采用“自动写入 + 可见 + 可修改 + 可删除 + 可撤销”的边界。

- `profile_candidate` 仍然必须用户确认。
- `task_create` 如果是明确的今日任务或短期任务，可以自动整理入库，但必须保留原始来源和可撤销能力。
- `short_term_state` 如果是明确的当前或近期状态，可以自动整理入库，但必须可见、可删、可失效。
- `life_event` 只有在用户明确表示“记一下”或语义风险很低时才考虑自动入库。
- 向量检索和行为模式推断先不做，等 MVP 测试证明它们确实能带来收益再补。

## 最小数据表设计

MVP 至少包含以下表：

### `raw_inputs`

保存用户原始输入。

用途：

- 保留用户真实说法。
- 方便追踪 AI 是从哪句话解析出的结构化条目。
- 用户删除时必须支持删除或停止使用。

### `ai_parse_results`

保存 AI 原始解析结果。

用途：

- 保存 DeepSeek 原始 JSON。
- 记录 schema 校验是否通过。
- 记录解析失败、重试、异常原因。

### `extracted_items`

保存等待用户确认的结构化条目。

用途：

- 表示“AI 猜出来的内容”。
- 不等于正式记忆。
- 用户可以确认、修改、拒绝。

### `tasks`

保存用户确认后的任务。

用途：

- 今日待办。
- 完成、取消、延期。
- 首页建议。
- 后续复盘素材。

### `short_term_states`

保存短期状态。

用途：

- 当前建议。
- 今日 / 最近几天上下文。
- 有有效期，过期后不再主动影响建议。

### `life_events`

保存生活事件 / 经验记录。

用途：

- 复盘素材。
- 经验沉淀。
- 不默认进入长期画像。

### `profile_items`

保存用户确认后的长期画像。

用途：

- 提醒偏好。
- 工作节奏。
- 沟通风格偏好。
- 长期背景。
- 首页建议和 AI 回复的少量个性化上下文。

## 数据状态流转

结构化条目和记忆需要明确状态，避免 AI 乱写入。

推荐状态：

- `pending`：AI 已解析，等待用户确认。
- `confirmed`：用户已确认，正式生效。
- `edited`：用户修改后确认。
- `rejected`：用户拒绝，不写入正式记录。
- `deleted`：用户删除，不再参与建议与检索。
- `expired`：短期状态过期，不再主动使用。
- `archived`：归档保留，但默认不主动调用。

核心规则：

```text
raw_inputs / ai_parse_results
→ extracted_items(pending)
→ 用户确认或修改
→ tasks / short_term_states / life_events / profile_items
```

不要把 `extracted_items` 直接当成正式记忆。

## AI 解析与 JSON 规则

DeepSeek 不应只输出自然语言回答，而应输出 App 可读取的结构化 JSON。

必须考虑：

- schema 校验。
- JSON 解析失败重试。
- 字段缺失兜底。
- 模糊时间保留原文，不要乱填日期。
- 置信度 `confidence`。
- 来源原文 `source_text`。
- 是否需要用户确认 `need_user_confirm`。
- 重复任务识别。
- 解析错误日志。

建议第一版用一个统一 envelope：

```json
{
  "user_reply": "我帮你整理出了这些内容，你可以确认或修改。",
  "input_summary": "用户提到明天联系王总、今天很累、不喜欢频繁提醒。",
  "intent_types": ["task_create", "short_term_state", "profile_candidate"],
  "items": []
}
```

每个 item 至少包含：

- `type`
- `title` 或 `content`
- `source_text`
- `tags`
- `confidence`
- `need_user_confirm`

## `short_term_state` 与 `profile_candidate` 的区分

### 短期状态

通常描述今天、最近几天、当前场景、临时身体或情绪状态。

示例：

- 我今天很累。
- 这两天睡眠不好。
- 我现在在路上，不方便打电话。
- 最近心情还不错。

处理方式：

- 写入 `short_term_states`。
- 设置有效期，例如今天、3 天、7 天。
- 可以参与首页建议。
- 用户可查看和删除。
- 不直接进入长期画像。

### 长期画像候选

通常描述稳定偏好、长期背景、习惯、工作方式。

示例：

- 我不喜欢太频繁的提醒。
- 我一般晚上效率比较高。
- 我经常出差。
- 我主要做项目现场相关工作。
- 我希望 AI 说话直接一点。

处理方式：

- 生成 `profile_candidate`。
- 必须用户确认或修改。
- 确认后写入 `profile_items`。
- 只有已确认画像才能参与建议。

判断红线：

- “今天很烦”不是长期画像。
- “最近有点拖延”不是长期画像。
- “今天客户让我不舒服”是事件，不是“我不喜欢客户沟通”。
- 多次行为模式总结后置，不在 MVP 自动生成。

## 首页建议规则

MVP 首页建议不做复杂检索，也不做行为模式分析。

只使用：

- 今日任务。
- 逾期任务。
- 未来 7 天重要任务。
- 未过期短期状态。
- 已确认的少量长期画像。

当前实现边界：

- `ContextBuilder` 已经作为首页建议的上下文选择入口。
- 目前支持 `current_suggestion` 和 `task_update_resolution`。
- intent 先用简单规则判断。
- 排除日志只记录原因数量，例如 `deleted`、`pending`、`expired`，不记录 raw input 或敏感正文。
- `HomeSuggestionService` 仍负责把上下文转成首页建议文案。
- 不要在这个阶段加入复盘、复杂个人问答、记忆编辑、summary 注入、向量检索或 LLM rerank。

建议输出应该克制：

- 给 1-3 个建议。
- 说明为什么。
- 避免命令式口吻。
- 不假装知道完整人生背景。

示例：

```text
你今天状态偏累，建议先处理一个低阻力但重要的小任务：联系王总。这个任务有明确对象，预计耗时短，完成后能减少待办压力。
```

## 隐私与后端原则

本项目数据高度敏感，包含任务、情绪、健康、客户、习惯、工作状态和长期画像。

MVP 原则：

- 本地优先。
- DeepSeek API Key 不放进移动端客户端。
- 使用最小后端 API proxy 保护 API Key。
- 服务端默认不保存用户原文。
- 日志默认脱敏。
- 用户可查看、修改、删除记忆。
- 上传给 DeepSeek 遵循最小必要上下文原则。
- 厂家不默认人工查看用户原始记录。

后置能力：

- 账号系统。
- 云同步。
- 端到端加密。
- 多设备冲突合并。
- 专业合规审查。

## 推荐项目结构

未来正式开发时，建议使用如下结构：

```text
myself/
  AGENTS.md
  AI_personal_memory_action_system_design_v0.2.md
  docs/
    architecture/
    superpowers/
      plans/
  apps/
    mobile/     # Flutter Android/iOS App
    api/        # 最小 DeepSeek API proxy
```

## 当前阶段路线图

旧的 Phase 0-6 路线已经完成其主要作用：项目不再是“从零搭建 MVP”，而是已经进入真实手机试用后的修复阶段。后续按 Phase 4 子阶段推进。

### Phase 4：真实试用信任修复阶段

目标：

```text
不丢内容
不乱显示今天/明天
更稳地理解任务取消/延期
删除和编辑让用户放心
首页解释更清楚
```

### Phase 4A：信任底座修复，已完成

交付：

- 保留最近 3 批 pending 待确认内容，连续整理不会让上一批待确认从页面消失。
- 任务、短期状态、生活事件、长期画像删除前增加二次确认。
- Debug 构建增加测试日期切换，便于验证今日任务和短期状态过期逻辑。
- 对应测试已补充，`flutter analyze` 和 `flutter test` 已通过。
- 提交：`c389778 feat: complete phase 4A trust fixes`。

### Phase 4B：时间语义与今日行动修复，已完成

交付：

- 增加 Time Reference Contract：移动端解析请求向 API / DeepSeek 传 `current_time_iso`，让“今天 / 明天 / 今晚”等相对时间以用户当时本地时间为基准。
- 预留可选 `location_context` 合同，默认不上传地点；未来只有用户授权定位后才作为解析上下文使用，且 prompt 明确没有地点时不得猜测位置。
- `晚上` / `今晚` / `今晚上` / `下午` / `上午` / `中午` / `傍晚` 等无其他日期修饰时，优先理解为今天对应时间段。
- 修复明天任务进入今日行动的问题，未安排任务不再默认算今日任务。
- 区分 `todayTasks`、`overdueTasks`、`upcomingTasks`、`unscheduledTasks`。
- 任务展示中明确具体日期和原始时间文本，为后续提醒能力打基础。
- 任务编辑入口从手填截止日期升级为日期 / 时间选择器，并支持清除时间。
- 对应验证已通过：`flutter analyze`、`flutter test`（118 tests）、`npm run typecheck`、API parser / schema / prompt 相关 Node 测试。
- 提交：`f62bba1 feat: complete phase 4B time fixes`。

已知缺口：

- `apps/api/test/privacyLogging.test.ts` 单独运行会挂住。该测试负责验证 API 错误日志不泄露用户原文，后续需要单独排查 server / fetch 生命周期。

### Phase 4C：task_update 真实语义增强，已完成

目标：

- 增强“取消了 / 不用了 / 不去了 / 不想去了 / 先不做了”等真实中文表达识别。
- 改进目标任务匹配，去掉“的事情 / 这个事 / 那个事”等噪声词。
- 对“健身不想去了”这类可能与长期目标冲突的表达，先进入确认或建议流程，不静默覆盖用户选择。
- 完成 / 取消任务已有业务状态展示：任务记录生命周期和任务业务状态已拆分为 `status` 与 `task_status`。

### Phase 4D：首页与行动区体验

已完成：

- 首页建议按任务依据、当前状态、长期偏好分组展示。
- 今日行动区域支持展开，能看到当天任务安排。
- AI 建议区域支持展开，展示 1-3 条建议及依据。
- 状态、画像、长期偏好之间使用更清晰的分隔和排版。

### Phase 4E：试用版可验证性和 APK 链路

已完成：

- 继续保持 Android 真机 APK + 本地 API proxy + DeepSeek 真实链路可跑。
- 明确 Debug / Release 网络配置差异。
- 后续如需给用户安装测试 APK，应单独记录构建命令、API 地址、设备网络前提和安全注意事项。
- 4E 文档：`docs/architecture/phase-4e-real-apk-trial.md`。

## 长期后续任务与产品记忆

以下内容来自 D0 讨论、Claude memory、Phase 3 真实试用反馈和 Phase 4A/4B 修复。它们不是 Phase 4C 必须一次做完的任务，但要保存在项目记忆里，避免后续忘掉。

### 1. prompt-accuracy：中文语义边界要继续校准

已知问题：

- DeepSeek Flash 曾把“晚上同学约我去网吧，我同意了”归为 `life_event`，但在本产品里它更应该是 `task_create`，因为这是未来安排、用户已同意、需要用户行动。
- parser prompt 和 sample set 需要覆盖社交约定、娱乐安排、客户拜访、生活预约、模糊时间、普通问答和长期画像边界。
- 分类不能只看关键词。“记得提醒我”可能是任务，但“我记得我读过这本书”不是任务。

当前状态：

- `docs/architecture/chinese-semantic-classification-rules.md` 已写入。
- `apps/api/src/services/parserPrompt.ts`、`parserSampleSet.ts` 和 smoke 检查已完成 D0 增强。
- 后续继续围绕真实失败样例补充规则和测试，不再把 D0 当作未完成阶段。

后续方向：

- Phase 4B 已补“晚上/今晚/下午”等同日隐含时间语义和当前时间上下文合同。
- 后续继续让 smoke 检查覆盖 `expectedTypes`、`forbiddenTypes`、`need_user_confirm`、`source_text`、模糊时间不乱造 `due_time_iso`。

### 2. task-time：时间粒度和提醒系统后置

已知问题：

- 当前移动端 `_inferTaskDue` 时间推断较粗，早期只覆盖“今天 / 明天 / 明天上午 / 明天下午”等有限表达。
- 用户真实表达会包含“下午三点”“晚上八点”“后天”“下周一”“过会儿”“回头”“有空”“等我到酒店后”等。
- “过会儿”通常是分钟到数小时；“回头”通常不是 15 分钟内；“有空”更低紧急度。

当前边界：

- Phase 4B 已修同日隐含时间、今日/未来任务过滤、时间展示和任务日期时间编辑入口。
- 完整提醒系统仍后置。
- 模糊时间优先保留 `due_time_text`，不乱填 `due_time_iso`。

后续方向：

- 未来由 parser 返回更准确的 `due_time_iso`。
- 移动端再扩展中文时间解析和 UI 展示。
- 真正提醒、稍后提醒、重复提醒另开阶段。

### 3. auto-save：自动保存边界要从关键词升级为语义判断

已知问题：

- `life_event` 自动保存不能只看“记一下”“记住”。真实用户会说“下次注意”“长了个教训”“以后要记住”等。
- `task_create` 自动保存不能只依赖本地 `_inferTaskDue` 是否识别出有限时间词。
- 漏掉一个需要提醒的任务，通常比重复提醒一个已完成任务更严重。

当前边界：

- `task_create` 对明确未来行动应更积极，可自动保存但必须可撤销。
- `profile_candidate` 仍必须用户确认。
- `general_answer` 当前默认只回答，不保存。

后续方向：

- 让 parser 负责主要语义分类，本地规则只做安全兜底。
- 自动保存必须坚持可见、可修改、可删除、可撤销。

### 4. 已完成 / 已取消任务的显示与清理

产品方向：

- 任务完成或取消后，不应马上从用户视野里彻底消失。
- 更合适的体验是划线、灰色、状态标签、来源原文、撤销入口。
- 未来可以让用户设置自动清理期限，例如 1 天、3 天或手动清理。

当前边界：

- Phase 4C 可以先增强取消/完成匹配和确认流程。
- 中期建议引入 `task_status: active / completed / cancelled`，不要长期混用 `record_status` 表达任务业务状态。

### 5. 模糊延期和双提醒

产品方向：

- 对明确延期，可以按新时间更新。
- 对低置信或时间模糊的延期，未来提醒系统可考虑保留原计划提醒，再加新计划提醒，降低漏提醒风险。
- 对提前量重要的事项，未来也可以提醒两次。

当前边界：

- Phase 4B 已改善任务时间展示和编辑入口。
- Phase 4C 可以继续改善延期识别和更新确认，但不实现完整提醒系统。

### 6. short_term_state 子类型与覆盖策略

状态不是一律追加，也不是一律覆盖。

后续建议：

- `location_state`：例如在路上、在办公室，最新状态优先，旧位置应失效。
- `energy_state` / `mood_state`：例如很累、开心、焦虑，可保留当天变化轨迹，但当前建议优先最新。
- `physical_state`：例如腰酸背疼、身体不舒服，可保留更长短期有效期。
- `availability_state`：例如不方便接电话、下午不适合重任务，按时间范围失效。
- `cognitive_state`：例如项目有点乱、注意力不集中，可作为 3-7 天近期状态。

当前边界：

- 当前只定义语义和后续策略，不新增 item type。

### 7. life_event 是未来自进化的重要证据

产品判断：

- `life_event` 表面上像普通记录，但它是未来理解用户生活、工作、习惯和经验的重要素材。
- 它未来可用于复盘、经验总结、长期画像候选生成、重要建议时调用过往经历。

当前边界：

- 当前不能从单条 `life_event` 自动生成正式长期画像。
- 即使未来从多条 `life_event` 生成 `profile_candidate`，也必须用户确认后才能生效。

### 8. 深度建议 / 长对话页面后置

产品方向：

- 大多数建议应该短、轻、克制。
- 但用户未来可能会问重要问题，需要根据长期画像、生活事件、近期状态、任务背景给更深入建议。
- 这可能需要独立页面和更强模型。

当前边界：

- Phase 4 不做深度建议页。
- 不做复杂个人问答、向量检索或完整 Agent。

### 9. 当前任务与长期画像 / 长期目标的冲突分析

产品方向：

- 用户表达“不想做某个当前任务”时，系统不能只按当前一句话机械取消任务。
- 未来要结合当前任务、短期状态、已确认长期画像、长期目标和任务重要性，判断这是不是“临时阻力”和“长期目标”的冲突。
- 示例：用户已有任务“今天下午去健身”，又说“今天好累，健身不想去了”。如果用户已确认的长期画像 / 目标是“想保持好身材”或“想改善健康”，系统更适合提醒这个冲突，并让用户选择继续、降低强度、延期或取消，而不是静默取消。
- 这类能力是未来自进化、智能提示和更深层建议的核心特征。

当前边界：

- 当前 MVP 不实现完整目标推理或价值判断。
- 只有用户确认过的 `profile_items` 或未来明确确认的长期目标可以参与判断，不能把未确认的 `profile_candidate` 当成事实。
- AI 只能建议、解释和请求确认，不能替用户做价值判断，也不能静默覆盖用户当前选择。

后续方向：

- ContextBuilder 需要能把相关任务、短期状态、已确认长期画像 / 目标一起取出。
- 任务更新流程需要区分“明确取消”和“当前不想做但可能与长期目标冲突”。
- 未来可以设计 goal-aware suggestion / conflict-aware task update 模块，先规则化，再考虑 LLM 辅助。

### 10. general_answer 的未来分支

当前原则：

- `general_answer` 默认作为可见回答，不生成保存卡片。

未来需要区分：

- 普通知识问答：像搜索引擎一样回答。
- 与用户背景相关的问题：未来可调用用户上下文回答。
- 重要工作/人生建议：未来可进入深度建议页面。
- 问答中夹带任务、状态、事件：拆出可结构化 item，回答部分仍走 `general_answer`。

## 后续开发协作规则

- 不要一上来做大而全功能。
- 不要重复创建 `apps/mobile` 或 `apps/api`，这两个项目已经存在。
- 开始新任务前先看当前 `main` 分支和 `git status --short --branch`，确认不是在旧主线或错误分支上执行。
- 每一阶段都要能独立运行和验证。
- 涉及数据结构时，优先保护用户可查看、可修改、可删除。
- 涉及 AI 输出时，永远先校验 JSON，再写数据库。
- 涉及长期画像时，必须用户确认后才能生效。
- 涉及隐私时，默认本地优先，默认最小上传。
- 开发前先看本文件和 MVP 计划文件。

## 当前下一步

当前下一步是 **每日复盘 `/review`**。AI 文字解析准确性增强、任务提醒、设置 / 个人页面骨架、账号登录和云端数据边界已经完成第一轮。

1. 先读 `docs/architecture/phase-5-task-map.md`，确认当前路线：Phase 5A 已完成第一版 → 每日复盘 `/review` → 复盘轻量服务任务建议。
2. 再看 `apps/mobile/lib/app/app_shell.dart`、`apps/mobile/lib/features/settings/profile_settings_screen.dart` 和 `apps/mobile/lib/features/review/review_screen.dart`，理解当前 App 入口和设置骨架。
3. 再看 `docs/architecture/phase-5a-account-cloud-data.md` 和 `docs/architecture/supabase/phase-5a-schema.sql`，理解 Supabase 配置、schema 和 RLS 边界。
4. 现有 `apps/api` 继续作为 DeepSeek proxy；不要把完整账号系统塞进当前 Express API。
5. 每日复盘应新增 `/review` 类能力，不继续压给 `/parse`；复盘 summary 必须可见、可编辑、可删除、可重新生成。
6. 复盘结果第一版只作为弱上下文服务首页任务建议，不自动创建任务、不自动修改任务、不自动生成长期画像。
7. 如果要先做云端数据落库，优先考虑只保存新生成的 summary；不要急着把全部 SQLite 历史记录做双向同步。
8. 学习目标、学习进展、学习卡点、电脑端、通用知识库、向量检索、自动画像进化、深度建议、个人问答、LLM rerank 和完整 Agent 都后置。
