# Phase 5 任务地图

日期：2026-06-18，更新：2026-06-22

状态：当前主任务地图。新 session 优先读本文件，再读 `AGENTS.md` 和
`README.md`。旧的“每日复盘 → 学习目标 → 学习进展 / 卡点 → 下一步建议”
连续路线已经取消为近期路线；学习目标和学习卡点后置，不进入当前实现范围。

## 1. 当前站位

Phase 4A-4E 已完成真实 Android 试用后的信任修复，Phase 5 前置 A / B
也已完成第一轮：

- AI 文字解析准确性增强已完成第一轮：语音化输入、混合意图、取消、延期、
  模糊时间和移动端兜底测试已补强。
- 本地任务提醒已完成第一轮：已确认、未完成、未取消、带未来 `dueTime` 的
  任务会安排系统通知；完成、取消、删除、清空时间会取消提醒。
- Android debug APK 已可构建，用户本机验证 `flutter build apk --debug` 通过。
- App 外壳已升级为 4 个底部入口：首页、任务、复盘、我的。
- “我的 / 设置”页面骨架已完成：账号、同步、提醒、复盘、AI、隐私、App
  状态等按钮结构已经稳定。
- Phase 5A 账号与云端数据已完成第一版：Supabase Flutter 依赖、环境变量
  初始化、邮箱 OTP 登录、退出登录、云端 schema/RLS、表权限、数据边界文档，
  以及本地 SQLite 到 Supabase 的手动单向同步第一版。
- “复盘”页面已完成第一版入口骨架，真实 `/review` 生成逻辑尚未接入。

当前产品判断：

```text
不要继续做大而全知识库。
不要把学习目标和学习卡点塞进近期范围。
先把 App 做成可以直接使用的成品：
账号登录与手动云同步已完成第一版 → 每日复盘 → 复盘轻量服务每日任务建议。
```

## 2. 当前 Phase 5 主目标

当前 Phase 5 的核心目标已经从“学习目标 / 卡点 / 教练式自进化”收窄为：

```text
用户可以不依赖同一个 Wi-Fi 使用 App，
可以登录账号并保存云端数据，
可以生成可编辑的每日复盘，
复盘结果能作为轻上下文服务今日任务建议，
但不会自动改任务、自动生成长期画像或自动替用户规划人生。
```

近期产品闭环：

```text
用户登录
→ 任务、状态、事件、画像可按账号手动同步到云端
→ 用户继续用自然语言记录任务和事件
→ App 本地提醒任务开始
→ 用户在复盘页生成今日复盘
→ 复盘 summary 可见、可编辑、可删除
→ 首页建议可以弱引用复盘，给出任务处理方式建议
```

这里的“复盘复用”第一版只做轻建议：

- 可以提醒用户某个任务适合先拆成小步骤；
- 可以结合当天状态提醒用户降低任务阻力；
- 可以解释建议依据来自今日任务、状态、生活事件或复盘 summary；
- 不自动创建任务；
- 不自动修改任务状态；
- 不把单日复盘变成长期画像；
- 不自动推断学习目标或学习卡点。

## 3. 当前执行顺序

### Phase 5 前置 A：AI 文字解析准确性，已完成

完成内容：

- API prompt 增加语音化 / 口语化输入、混合意图、可靠时间和歧义时间边界。
- Parser sample set 增加真实中文样例。
- Smoke 评估增加裸时钟歧义检查。
- 移动端 `task_due_inference.dart` 支持“后天 / 大后天 / 下周一下午三点”等安全兜底。
- 移动端 `task_update_matcher.dart` 增强口语取消和延期噪声清洗。
- 新增移动端测试覆盖时间兜底和任务更新匹配。

边界：

- `/parse` 继续只做结构化入库；
- 不把复盘、知识库、个人问答或教练能力塞进 `/parse`。

### Phase 5 前置 B：本地任务提醒，已完成

完成内容：

- 新增 `TaskReminderScheduler` / `TaskReminderCoordinator`。
- 接入 `flutter_local_notifications` 和 `timezone`。
- Android / iOS 已配置基础通知能力。
- App 启动初始化通知插件。
- 任务确认、自动保存、编辑、完成、取消、删除等路径已接入提醒同步。
- Android 使用 `inexactAllowWhileIdle`，暂不申请精确闹钟权限。

当前提醒范围：

- 只提醒任务本身；
- 不提醒任务更新；
- 不提醒任务删除；
- 不做重复提醒；
- 不做云端提醒；
- 不做多设备提醒。

可后续微调：

- 默认提醒时间：准时 / 提前 5 分钟 / 提前 10 分钟 / 提前 30 分钟。
- 在任务 UI 中显示提醒状态。

### Phase 5 前置 C：设置 / 个人页面，已完成第一版

目标：

- 给后续账号、同步、复盘、AI、隐私、通知能力提供稳定入口。

完成内容：

- 底部导航新增 4 个入口：首页、任务、复盘、我的。
- 任务页从隐藏入口变成一级导航。
- 复盘页新增“今日复盘”入口骨架。
- 我的页新增账号卡片、今日数据概览、快捷入口和设置分组。
- 设置分组包括：
  - 账号与同步；
  - 提醒与任务；
  - 复盘设置；
  - AI 与记忆；
  - 隐私与数据；
  - App 与帮助。
- 危险数据操作使用确认弹窗占位。
- “复盘结果参与首页建议”已有开关 UI，后续接 ContextBuilder。

关键文件：

- `apps/mobile/lib/app/app_shell.dart`
- `apps/mobile/lib/features/review/review_screen.dart`
- `apps/mobile/lib/features/settings/profile_settings_screen.dart`
- `apps/mobile/test/widget_test.dart`

验证：

- `cd apps/mobile && flutter analyze --no-pub`
- `cd apps/mobile && flutter test`

### Phase 5A：账号与云端数据

完成状态：已于 2026-06-18 完成账号第一版；2026-06-22 补齐手动单向云同步第一版。

目标：

- 让 App 不再依赖本地 API proxy + 同 Wi-Fi 调试链路，用户可以登录账号后直接使用。

推荐方案：

- 账号：邮箱验证码登录。
- 数据：云端优先，推荐 Supabase Auth + Postgres + Row Level Security。
- 现有 Express API 继续作为 DeepSeek proxy，不承担完整账号系统。
- 手机端可以保留本地缓存，但第一版不做复杂离线双向同步。

第一版要做：

- Supabase 项目配置文档。已完成：
  `docs/architecture/phase-5a-account-cloud-data.md`
- Flutter Supabase client 接入。已完成：
  `supabase_flutter`
- 登录 / 注册 / 退出登录页面。已完成邮箱 OTP 登录骨架和退出登录。
- 用户 session 持久化。由 `supabase_flutter` 内置本地存储负责。
- 云端表结构、RLS 和 authenticated 表权限。已完成：
  `docs/architecture/supabase/phase-5a-schema.sql`
- 把任务、状态、事件、画像等用户数据增加 `user_id` 归属。已在云端 schema
  中完成。
- 本地 SQLite 到 Supabase 的手动单向同步。已完成第一版：
  - `raw_inputs`
  - `ai_parse_results`
  - `extracted_items`
  - `tasks`
  - `short_term_states`
  - `life_events`
  - `profile_items`
  - 同步方式为本地全量 upsert 到云端，同 id 更新，不存在则插入。
- 明确本地 SQLite 在云端化后的角色：缓存 / 迁移源 / 离线兜底。已写入
  Phase 5A 文档。

运行配置：

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

如果没有传入这两个值，App 仍可运行，但“我的”页会显示“未配置云端”。

暂不做：

- 第三方登录；
- 会员订阅；
- 多设备冲突合并；
- 端到端加密；
- 复杂离线编辑队列。
- 从云端反向拉取并合并到本地 SQLite；
- 提交 / 确认 / 删除后的自动实时同步。

后续可选路径：

- 先做 Phase 5B `/review`，把新生成的 summary 存入云端；
- 或把当前手动同步升级为提交 / 确认 / 删除后的自动同步触发。

当前建议优先做 Phase 5B，因为账号和手动云同步已经能支撑真实试用；自动同步可作为 Phase 5A.2 小增强穿插完成。

### Phase 5B：每日复盘 `/review`

完成状态：2026-06-22 已完成第一版。

目标：

- 根据当天可见记录和用户补充文字生成简洁、可编辑、有来源依据的每日复盘。
- 复盘页采用“月份 → 周 → 天”的文件夹式浏览结构，避免历史复盘堆成一长串。

输入来源：

- 今日任务；
- 已完成 / 已取消任务；
- 短期状态；
- 生活事件；
- 用户补充的复盘文字；
- 少量已确认长期画像，只用于解释提醒偏好或表达风格。

输出：

- `daily_summary`；
- 鼓励话语 `encouragement`；
- 当天不足与改进建议 `improvement_notes`；
- 任务处理建议 `task_guidance`；
- 未解决事项 `open_items`；
- 来源引用 `source_refs`；
- 置信度或不确定说明。

第一版已落地：

- API 新增独立 `/review` schema、prompt、DeepSeek service 和 route，不把复盘塞进 `/parse`。
- 移动端新增本地 `summaries` / `summary_sources` 表，summary 可保存、编辑、删除、重新生成。
- 复盘页按月展示，每个月拆成周文件夹，点具体日期查看当天复盘。
- 生成复盘前允许用户补充当天感受。
- 复盘内容包含今日总结、鼓励、今天的不足、任务处理建议、未解决事项和来源依据数量。
- 手动云同步已纳入 `summaries` / `summary_sources`。
- Supabase schema 为 `summaries` 补充 `encouragement` 和 `improvement_notes` 字段。

模型建议：

- `/parse` 继续使用低温度结构化配置。
- `/review` 使用单独 prompt 和模型配置，可用 DeepSeek v4-pro，温度可高于解析链路。
- 即使复盘更自然，也必须做 schema 校验；能入库的 summary 必须可见、可编辑、可删除、可重新生成。

边界：

- 单日复盘不能自动变成长期画像；
- 不自动生成学习目标；
- 不自动生成学习卡点；
- 不自动创建任务，除非用户后续选择“加入任务”；
- 不读取被删除记录；
- 不使用未确认画像作为事实。
- 复盘 summary 暂不自动影响首页建议；这留给 Phase 5C。

### Phase 5C：复盘轻量服务每日任务

完成状态：2026-06-22 已完成第一版。

目标：

- 让首页建议不只是“推荐干什么”，也能给“怎么处理这个任务”的轻量指导。

第一版建议形态：

- “你今天状态偏累，这个任务可以先做 10 分钟启动版。”
- “这个任务有明确时间，建议先确认材料或地点，避免临近才处理。”
- “今天已经有几个任务，建议只保留一个最关键的行动。”

实现方式：

- ContextBuilder 增加弱上下文来源：active `daily_summary`。
- 首页建议服务读取复盘 summary 时必须显示来源说明。
- 复盘 summary 权重低于当前任务、当前输入和已确认长期画像。
- 我的页里的“复盘结果参与首页建议”开关已接入运行时选择逻辑；持久化到本地设置后续再补。

第一版已落地：

- `ContextBuilder.buildCurrentSuggestion` 会读取最近 7 天最多 3 条 active / edited `daily_summary`。
- 首页建议服务会在建议理由中显示“近期复盘”弱上下文。
- 复盘 summary 不参与任务排序，不覆盖任务、短期状态或长期画像。
- Debug JSON 只显示 summary 数量，不暴露 summary 正文。
- 关闭“复盘结果参与首页建议”后，首页不会读取复盘 summary。

边界：

- 不自动重排任务；
- 不自动取消任务；
- 不自动创建任务；
- 不做价值判断；
- 不把复盘当作长期事实。

### Phase 5D：AI 时间规划与类课表日历，待做

目标：

- 在任务、短期状态、长期画像和复盘 summary 的基础上，让 AI 生成可编辑的时间规划草稿。
- 用类似课表 / 日历 / time blocking 的界面展示一天或一周的时间块。
- 用户可以修改、拖动、删除、确认 AI 安排；AI 不直接静默改任务。

参考成熟工具：

- Super Productivity：参考 todo + timeboxing + time tracking + 日历导入的组合方式。
- Tasks.org：参考成熟移动端任务管理、提醒和任务详情体验。
- Vikunja：参考自托管任务 / 项目 / 列表组织方式。
- AppFlowy：参考更大 AI 工作空间中任务、文档和 AI 辅助的关系，但当前不做大而全工作台。

第一版建议范围：

- 先做单日时间规划，不直接做完整周/月复杂日历。
- 输入来源包括今日任务、未来 7 天任务、未过期短期状态、已确认长期偏好和最近复盘 summary。
- AI 输出“时间块草稿”，每块包含开始时间、结束时间、任务、建议原因、可调整说明。
- 用户确认后才写入正式计划；未确认前只是草稿。
- 支持手动更改时间块，后续再考虑拖拽、冲突检测、重复计划和时间追踪。

边界：

- 不自动完成、取消、延期任务；
- 不替用户做价值判断；
- 不根据单日复盘生成长期习惯结论；
- 不做完全自主 Agent 排程；
- 不在第一版做复杂多设备冲突合并。

### Phase 5E：可控记忆管理增强

目标：

- 让用户看懂哪些任务、状态、事件、画像和复盘 summary 会影响后续建议。

需要能力：

- 查看来源；
- 编辑；
- 删除；
- 归档；
- 必要时恢复；
- 显示某条记录是否参与建议。

这一步可以在账号云端化和 `/review` 跑通后再做。

## 4. AI 能力边界

近期只保留三个实际入口：

```text
/parse
  结构化入库：任务、状态、事件、画像候选、普通回答。

/review
  每日复盘：日总结、任务处理建议、未解决事项、来源引用。

/memory
  记忆管理：查看、编辑、删除、恢复、解释来源。
```

`/coach` 暂不作为近期实现入口。未来如果要做目标对齐、学习进展、卡点和深度建议，再重新设计 `/coach`。

给初学者可以这样理解：

```text
/parse  问的是：这句话应该保存成什么？
/review 问的是：今天发生了什么，下一次处理类似任务要注意什么？
/memory 问的是：App 现在记住了什么，我能不能控制？
```

## 5. 暂不进入的范围

这些不是当前 Phase 5 小闭环的近期任务：

- 学习目标记录；
- 学习进展记录；
- 学习卡点抽取；
- `/coach` 目标对齐；
- 完整电脑端客户端；
- 通用知识库；
- 向量检索；
- 自动长期画像进化；
- 广泛个人问答；
- 完全自主 Agent 规划；可控 AI 时间规划已单独放入 Phase 5D；
- 重复提醒和多设备提醒；
- LLM rerank；
- 会员订阅和商业化。

## 6. 新 session 推荐入口

1. `AGENTS.md`：项目记忆和协作规则。
2. `README.md`：当前能力和目录入口。
3. `docs/architecture/phase-5-task-map.md`：当前 Phase 5 主路线。
4. `docs/architecture/current-verification.md`：最近验证记录。
5. `apps/mobile/lib/app/app_shell.dart`：底部导航入口。
6. `apps/mobile/lib/features/settings/profile_settings_screen.dart`：我的 / 设置页面。
7. `apps/mobile/lib/features/review/review_screen.dart`：复盘入口骨架。
8. `docs/architecture/summary-system-design.md`：summary 表和来源追踪设计。
9. `docs/architecture/context-builder-design.md`：后续复盘参与建议的上下文边界。

## 7. 相关文档

- `docs/architecture/summary-system-design.md`：summary / compressed context 设计背景。
- `docs/architecture/context-builder-design.md`：ContextBuilder 方向。
- `docs/architecture/phase-5-reflection-goals-evolution.md`：长期方向文档，注意其中学习目标 / 卡点路线已后置。
- `docs/architecture/task-update-resolution.md`：任务更新匹配边界。
- `docs/architecture/phase-4e-real-apk-trial.md`：真实 APK 试用链路。
