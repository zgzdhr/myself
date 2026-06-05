# AI 个人记忆与行动整理系统：项目协作记忆

## 项目定位

本项目不是普通 To-do List，也不是“大而全 AI 管家”。

更准确的定义是：

> 一个面向 Android 与 iOS 的个人记忆与行动整理 App。用户用自然语言输入任务、状态、经历、偏好和问题，系统用 AI 解析为结构化数据，经用户确认后写入本地记忆，并在后续建议、复盘和回复中调用这些记忆。

产品灵魂是：

> 这句话对用户未来有没有价值？如果有，应该保存到哪里、保存多久、什么时候再次拿出来用？

## 当前规划状态

截至 2026-06-05，项目已经进入 MVP 骨架稳定阶段，Flutter App、API proxy、本地数据库、解析链路和基础确认流程已经存在，不再是空项目或纯规划阶段。

已确认的核心链路：

```text
万能输入框
→ DeepSeek 解析 JSON
→ schema 校验
→ 生成 extracted items
→ 用户确认 / 修改 / 拒绝
→ 写入本地数据库
→ 首页基于今日任务、短期状态、已确认长期画像给简单建议
```

重要源文档：

- `README.md`：项目入口说明。
- `AI_personal_memory_action_system_design_v0.2.md`：ChatGPT 生成的产品与系统设计讨论稿。
- `docs/superpowers/plans/2026-05-31-personal-memory-action-system-mvp.md`：Codex 整理的 MVP 开发实施计划。

## 目标平台与技术方向

本项目未来明确面向两个移动端版本：

- Android App
- iOS App

建议优先使用 Flutter 开发一套跨平台移动端代码，同时支持 Android 与 iOS。

MVP 推荐技术方向：

- 移动端：Flutter。
- 本地数据库：SQLite，推荐 Drift 作为 Flutter 侧数据库层。
- 状态管理：优先 Riverpod，避免一开始做复杂架构。
- 后端：最小 Node.js / TypeScript API proxy，只负责转发 DeepSeek 请求和保护 API Key。
- AI：DeepSeek，输出结构化 JSON。
- 数据策略：local-first，本地优先，云同步后置。

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

## 开发阶段路线图

### Phase 0：项目地基

目标：建立 Flutter + API proxy + 文档结构。

交付：

- `apps/mobile` Flutter 项目。
- `apps/api` TypeScript API proxy。
- `.env.example`。
- 基础 README。

### Phase 1：本地数据层

目标：先让 App 能保存、读取、删除结构化数据。

交付：

- Drift / SQLite schema。
- 7 张 MVP 表。
- 数据状态流转。
- 本地测试。

### Phase 2：AI 解析闭环

目标：用户输入一句话，DeepSeek 返回结构化 JSON，App 生成待确认卡片。

交付：

- 后端 `/parse` 接口。
- JSON Schema / Zod 校验。
- 移动端 parser client。
- 解析失败兜底。

### Phase 3：确认与写入

目标：用户能确认、修改、拒绝 AI 解析结果。

交付：

- extracted item 卡片。
- 确认后写入正式表。
- 拒绝后不生效。
- 修改后记录 edited 状态。

### Phase 4：首页建议

目标：首页能根据任务、短期状态、已确认画像给简单建议。

交付：

- 今日任务列表。
- 近期状态展示。
- 当前建议卡片。
- 简单建议规则。

### Phase 5：记忆管理

目标：用户能看到 AI 记住了什么，并能删除。

交付：

- 任务页。
- 短期状态页。
- 生活事件页。
- 长期画像页。
- 删除 / 归档能力。

### Phase 6：Android / iOS 验证

目标：确认同一套 Flutter 代码能在 Android 与 iOS 上运行。

交付：

- Android 模拟器可运行。
- iOS 模拟器可运行。
- 本地数据库在两端可用。
- 基础输入与确认流程可用。

## 后续开发协作规则

- 不要一上来做大而全功能。
- 每一阶段都要能独立运行和验证。
- 涉及数据结构时，优先保护用户可查看、可修改、可删除。
- 涉及 AI 输出时，永远先校验 JSON，再写数据库。
- 涉及长期画像时，必须用户确认后才能生效。
- 涉及隐私时，默认本地优先，默认最小上传。
- 开发前先看本文件和 MVP 计划文件。

## 当前下一步

正式开发前，下一步应该是：

1. 确认 Flutter + Node.js API proxy 的技术选型。
2. 创建 `apps/mobile` 和 `apps/api` 项目骨架。
3. 先做本地数据库和 mock parser，不急着接 DeepSeek。
4. 再接入真实 DeepSeek 解析接口。
5. 最后做首页建议与记忆管理页面。
