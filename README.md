# AI Personal Memory Action System

这是一个面向 Android 与 iOS 的个人记忆与行动整理 App 项目。

核心目标不是做普通 To-do List，而是让用户用自然语言输入任务、状态、经历、偏好和问题，再由 AI 解析成可确认、可修改、可删除的结构化个人记忆。

## 当前状态

项目仍处于正式开发前的准备阶段，底层产品规划和 MVP 范围已经收敛。

优先阅读：

- `AGENTS.md`：给 Codex / Claude / 后续开发 Agent 的项目记忆和协作规则。
- `AI_personal_memory_action_system_design_v0.2.md`：最初的产品与系统设计讨论稿。
- `docs/superpowers/plans/2026-05-31-personal-memory-action-system-mvp.md`：MVP 实施计划。

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
→ 首页基于今日任务、短期状态、已确认长期画像给简单建议
```

## 技术方向

- 移动端：Flutter，同时支持 Android 与 iOS。
- 本地数据库：SQLite，推荐 Drift。
- 状态管理：Riverpod。
- 后端：最小 Node.js / TypeScript API proxy，用于保护 DeepSeek API Key。
- AI：DeepSeek 结构化 JSON 输出。
- 数据策略：local-first，本地优先，云同步后置。
