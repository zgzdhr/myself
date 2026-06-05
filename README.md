# AI Personal Memory Action System

这是一个面向 Android 与 iOS 的个人记忆与行动整理 App 项目。

核心目标不是做普通 To-do List，而是让用户用自然语言输入任务、状态、经历、偏好和问题，再由 AI 解析成可确认、可修改、可删除的结构化个人记忆。

## 当前状态

项目已经进入 MVP 骨架稳定阶段，核心链路和基础结构已经落地，不再是正式开发前的纯规划状态。

当前已经落地：

- Flutter 移动端项目，包含 Android 与 iOS 原生工程目录。
- Riverpod App Shell、首页、万能输入页、待确认卡片和记忆入口页面。
- Drift / SQLite 本地数据库 schema，覆盖 raw inputs、AI parse results、extracted items、tasks、short-term states、life events、profile items。
- Parser domain models，包含 `task_create`、`task_update`、`short_term_state`、`life_event`、`general_answer`、`profile_candidate` 等 MVP 类型。
- Mock Parser 与 HTTP Parser Client，移动端可以先跑 mock，也可以通过本地 API proxy 调真实解析。
- TypeScript API proxy，包含 `/parse` route、Zod schema 校验、DeepSeek parser service、prompt、sample set 和隐私日志测试。
- Phase 2 DeepSeek smoke workflow，用于验证真实模型能返回符合 schema 的结构化 JSON。
- Task 10/11 架构设计文档，覆盖小总结机制和受控 Context Builder。
- 第一版最小 ContextBuilder，当前只支持 `current_suggestion`，并被首页建议复用。
- 基础测试覆盖，包括 Flutter analyze/test 目标、API typecheck/test 目标，以及 parser、数据库、确认流、记忆管理和隐私失败处理测试。

优先阅读：

- `AGENTS.md`：给 Codex / Claude / 后续开发 Agent 的项目记忆和协作规则。
- `AI_personal_memory_action_system_design_v0.2.md`：最初的产品与系统设计讨论稿。
- `docs/superpowers/plans/2026-05-31-personal-memory-action-system-mvp.md`：MVP 实施计划。
- `docs/architecture/phase-2-ai-parse-smoke.md`：真实 DeepSeek 解析 smoke 流程说明。
- `docs/architecture/mobile-smoke-test.md`：移动端 smoke 验证记录。
- `docs/architecture/current-verification.md`：当前自动化验证结果。
- `docs/architecture/summary-system-design.md`：Task 10 小总结机制设计。
- `docs/architecture/context-builder-design.md`：Task 11 受控 Context Builder 设计。

## Apps

- `apps/mobile`: Flutter Android/iOS app.
- `apps/api`: Minimal TypeScript DeepSeek API proxy.

## MVP 闭环

```text
万能输入框
→ DeepSeek 解析 JSON
→ schema 校验
→ 生成 extracted items
→ 用户确认 / 修改 / 拒绝
→ 写入本地数据库
→ ContextBuilder 选择 current_suggestion 所需上下文
→ 首页基于今日任务、短期状态、已确认长期画像给简单建议
```

## 技术方向

- 移动端：Flutter，同时支持 Android 与 iOS。
- 本地数据库：SQLite，推荐 Drift。
- 状态管理：Riverpod。
- 后端：最小 Node.js / TypeScript API proxy，用于保护 DeepSeek API Key。
- AI：DeepSeek 结构化 JSON 输出。
- 数据策略：local-first，本地优先，云同步后置。

## 自动写入策略

- 长期画像必须用户确认后才能正式生效。
- 今日任务和短期状态可以在规则明确时自动整理，但必须可见、可修改、可删除、可撤销。
- 向量检索和行为模式推断先不做，等 MVP 真实测试证明需要再补。

## 当前 ContextBuilder 边界

- 已实现：`apps/mobile/lib/features/context/context_builder.dart`
- 当前只支持：`current_suggestion`
- 复用位置：`apps/mobile/lib/features/home/home_suggestion_service.dart`
- 测试位置：`apps/mobile/test/features/context/context_builder_test.dart`
- 排除日志：只记录原因数量，不记录 raw input 或敏感正文。
- 后置能力：复盘、复杂个人问答、记忆编辑、summary 注入、向量检索、LLM rerank。

## 下一阶段

下一阶段先做稳定化，不扩大成完整 AI Agent：

- 基于当前 `current_suggestion` ContextBuilder 做小步扩展。
- 优先补解释性 UI 或 `task_update` 上下文匹配。
- `daily_review`、`weekly_review`、复杂个人问答和记忆编辑后置。
- 不做完整 Agent，不做向量检索，不做行为模式推断。
