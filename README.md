# AI Personal Memory Action System

这是一个面向 Android 与 iOS 的个人记忆与行动整理 App 项目。

核心目标不是做普通 To-do List，而是让用户用自然语言输入任务、状态、经历、偏好和问题，再由 AI 解析成可确认、可修改、可删除的结构化个人记忆。

## 当前状态

项目已经从 MVP 骨架稳定阶段进入真实手机试用后的可用性修正阶段。核心链路已经能在 Android 真机上通过本地 API proxy 调用 DeepSeek 并写入本地 SQLite。Phase 4A 已完成待确认批次保留、删除二次确认和 Debug 日期切换；Phase 4B 已完成时间上下文、可选地点上下文合同、时间语义、今日行动过滤、时间展示和日期时间编辑器。当前下一步是 Phase 4C，重点增强 `task_update` 取消 / 完成 / 延期表达和目标任务匹配。

当前已经落地：

- Flutter 移动端项目，包含 Android 与 iOS 原生工程目录。
- Riverpod App Shell、首页、万能输入页、待确认卡片和记忆入口页面。
- Drift / SQLite 本地数据库 schema，覆盖 raw inputs、AI parse results、extracted items、tasks、short-term states、life events、profile items。
- Parser domain models，包含 `task_create`、`task_update`、`short_term_state`、`life_event`、`general_answer`、`profile_candidate` 等 MVP 类型。
- Mock Parser 与 HTTP Parser Client，移动端可以先跑 mock，也可以通过本地 API proxy 调真实解析。
- TypeScript API proxy，包含 `/parse` route、Zod schema 校验、DeepSeek parser service、prompt、sample set 和隐私日志测试。
- Phase 2 DeepSeek smoke workflow，用于验证真实模型能返回符合 schema 的结构化 JSON。
- Task 10/11 架构设计文档，覆盖小总结机制和受控 Context Builder。
- ContextBuilder 已支持 `current_suggestion` 和 `task_update_resolution`，并被首页建议和任务更新匹配复用。
- Phase 3 真实试用文档，记录三星 Android 真机 APK、API proxy、DeepSeek 解析链路和 Phase 4 问题来源。
- Phase 4A 信任底线修复：最近 3 批 pending 待确认内容保留、记忆删除二次确认、Debug 日期切换。
- Phase 4B 时间语义与今日行动修复：当前时间传给 DeepSeek、可选地点上下文合同、同日隐含时间、今天 / 明天 / 未来 / 未安排任务分组、任务时间展示、日期时间编辑器。
- 基础测试覆盖，包括 Flutter analyze/test 目标、API typecheck/test 目标，以及 parser、数据库、确认流、记忆管理和隐私失败处理测试。

优先阅读：

- `AGENTS.md`：给 Codex / Claude / 后续开发 Agent 的项目记忆和协作规则。
- `AI_personal_memory_action_system_design_v0.2.md`：最初的产品与系统设计讨论稿。
- `docs/superpowers/plans/2026-05-31-personal-memory-action-system-mvp.md`：MVP 实施计划。
- `docs/architecture/phase-2-ai-parse-smoke.md`：真实 DeepSeek 解析 smoke 流程说明。
- `docs/architecture/mobile-smoke-test.md`：移动端 smoke 验证记录。
- `docs/architecture/current-verification.md`：当前自动化验证结果。
- `docs/architecture/phase-3-verification.md`：Phase 3 验收和真实试用结论。
- `docs/architecture/phase-3-real-trial-feedback.md`：三星 Android 真机真实试用反馈。
- `docs/architecture/summary-system-design.md`：Task 10 小总结机制设计。
- `docs/architecture/context-builder-design.md`：Task 11 受控 Context Builder 设计。
- `2026-06-05-mvp-next-task-map.md`：当前 Phase 4 任务地图。

## Apps

- `apps/mobile`: Flutter Android/iOS app.
- `apps/api`: Minimal TypeScript DeepSeek API proxy.

## 验证

根目录提供统一检查脚本，用于一次跑完移动端和 API 的基础验证：

```bash
./scripts/check-all.sh
```

脚本会依次执行：

- `cd apps/mobile && flutter analyze`
- `cd apps/mobile && flutter test`
- `cd apps/api && npm run typecheck`
- `cd apps/api && npm test`

在受限沙箱环境里，Flutter SDK cache 写入和 API localhost 隐私测试可能需要权限模式；本机正常开发环境可直接运行。

## MVP 闭环

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
- 当前支持：`current_suggestion`、`task_update_resolution`
- 复用位置：`apps/mobile/lib/features/home/home_suggestion_service.dart`、任务更新匹配流程
- 测试位置：`apps/mobile/test/features/context/context_builder_test.dart`
- 排除日志：只记录原因数量，不记录 raw input 或敏感正文。
- 后置能力：复盘、复杂个人问答、记忆编辑、summary 注入、向量检索、LLM rerank。

## 真实试用发现的主要问题

Phase 3 三星 Android 真机试用说明：App 已经可以真实运行和调用 DeepSeek，但还不够可信、不够顺手。下一阶段重点不是继续扩“智能”，而是先修信任底线。

当前最重要的问题：

- 待确认内容不能丢：连续点击“整理”后，上一批未确认内容不能从页面消失。
- 时间语义要更符合中文日常表达：`晚上` / `今晚` / `下午` 默认通常应理解为今天对应时间段。（Phase 4B 已完成第一版）
- 今日行动不能混入明天任务；无明确日期的任务应单独处理，而不是默认都算今天。（Phase 4B 已完成第一版）
- `task_update` 取消表达还太脆，例如“下午开会的事情取消了”和“健身不想去了”需要更稳的匹配和确认。
- 任务截止时间需要日期/时间选择器，未来提醒需要具体日期和时间。（Phase 4B 已完成编辑入口，完整提醒仍后置）
- 记忆删除需要二次确认，后续再做批量删除。
- 首页建议和今日行动需要更清晰的分组、展开和多建议展示。

## 当前阶段

当前阶段是 **Phase 4：真实试用信任修复阶段**。

目标：

```text
不丢内容
不乱显示今天/明天
能更稳地理解任务取消/延期
允许用户安全删除
让首页解释更清楚
```

阶段进度：

1. Phase 4A：信任底座修复，已完成。
   - 保留 pending 确认批次。
   - 删除操作确认弹窗。
   - Debug 日期切换能力。
2. Phase 4B：时间语义与今日行动修复，已完成。
   - 当前时间上下文传给 DeepSeek。
   - 可选地点上下文合同，默认不上传地点。
   - 同日隐含时间语义：晚上 / 今晚 / 下午。
   - 今天 / 明天 / 未来 / 未安排任务过滤修复。
   - due time 展示规则和日期时间编辑器。
   - 提交：`f62bba1 feat: complete phase 4B time fixes`。
3. Phase 4C：`task_update` 取消表达和目标匹配增强，当前下一步。
4. Phase 4D：首页建议解释分组、今日行动展开、多建议展示。

仍然不做：

- 完整 AI Agent。
- 向量检索。
- 自动长期画像进化。
- 云同步。
- 复杂日 / 周 / 月复盘。
