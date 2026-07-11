# Phase 5 任务地图

日期：2026-06-18，更新：2026-07-06

状态：当前主任务地图。新 session 优先读本文件，再读 `AGENTS.md` 和
`README.md`。旧的“每日复盘 → 学习目标 → 学习进展 / 卡点 → 下一步建议”
连续路线已经取消为近期路线；账号、云端、国内发布稳定化也先后移。
当前优先补齐统一日历、每日重复任务和“开始久坐”会话。

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
任务、时间规划、重复任务和久坐提醒要先在手机上形成可用闭环。
```

## 2. 当前 Phase 5 主目标

当前 Phase 5 的核心目标已经从“学习目标 / 卡点 / 教练式自进化”收窄为：

```text
用户能在一个统一日历里看任务和时间规划，
能用普通新建任务流程创建每日重复任务，
能在首页开始久坐会话并收到活动提醒，
能拖拽周历里的任务和时间块调整安排，
但 AI 不静默完成、取消、删除或重写任务。
```

近期产品闭环：

```text
用户打开首页
→ 可以继续用万能输入记录任务和事件
→ 可以点“开始久坐”进入手动会话
→ 到时提醒站起来活动
→ 进入任务页看到统一日历
→ 月历看任务 / 时间块分布
→ 周历看 7 天任务和时间块，并可拖拽调整
→ 新建任务时可选择“重复任务”和重复范围
→ 每日重复规则生成当天任务实例
```

这里的“统一日历”第一版只做可控调整：

- 可以拖拽周历里的任务或时间块；
- 可以更新任务日期 / 时间或时间规划块的开始结束时间；
- 可以展示任务、重复任务实例、AI 时间规划块和久坐会话；
- 不自动完成任务；
- 不自动取消任务；
- 不把重复行为自动写成长期画像；
- 不做传感器姿势检测。

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

### Phase 5D：AI 时间规划与类课表日历

完成状态：2026-06-23 已完成第一版。

目标：

- 在任务、短期状态、长期画像和复盘 summary 的基础上，让 AI 生成可编辑的时间规划草稿。
- 用类似课表 / 日历 / time blocking 的界面展示一天或一周的时间块。
- 用户可以修改、拖动、删除、确认 AI 安排；AI 不直接静默改任务。

参考成熟工具：

- Super Productivity：参考 todo + timeboxing + time tracking + 日历导入的组合方式。
- Tasks.org：参考成熟移动端任务管理、提醒和任务详情体验。
- Vikunja：参考自托管任务 / 项目 / 列表组织方式。
- AppFlowy：参考更大 AI 工作空间中任务、文档和 AI 辅助的关系，但当前不做大而全工作台。

第一版已落地：

- API 新增独立 `/plan` route、schema、DeepSeek plan service 和 prompt。
- `/plan` 输入今日 / 未来 7 天任务、未过期短期状态、已确认长期画像和近期复盘 summary。
- AI 输出“时间块草稿”，每块包含开始时间、结束时间、类型、关联任务、备注、安排原因和来源引用。
- 移动端新增 `schedule_plans`、`schedule_blocks`、`schedule_block_sources` 本地表，Drift schema 升级到 version 4。
- 复盘页新增“每日复盘 / 时间规划”两个 tab。
- 时间规划页按周选择具体日期，并以类课表时间轴展示当天时间块。
- 用户可以生成 AI 草稿、确认计划、编辑时间块、删除时间块、删除整份计划。
- 手动云同步已纳入 `schedule_plans`、`schedule_blocks`、`schedule_block_sources`。
- Supabase schema 已新增三张时间规划表，启用 RLS，并授予 authenticated 角色 `select / insert / update` 权限。

第一版产品取舍：

- 借鉴 Super Productivity 的 timeboxing 思路，但不做第一版时间追踪、工时统计或外部日历导入。
- 借鉴 Tasks.org 的移动端任务细节和提醒边界，但不把时间规划直接改写任务状态。
- 借鉴 Vikunja 的列表 / 项目组织意识，但当前仍以个人单日计划为主，不做复杂项目管理。
- 借鉴 AppFlowy 的 AI 辅助与数据控制关系，但不扩展成大而全 AI 工作空间。

边界：

- 不自动完成、取消、延期任务；
- 不替用户做价值判断；
- 不根据单日复盘生成长期习惯结论；
- 不做完全自主 Agent 排程；
- 不在第一版做复杂多设备冲突合并。
- 当前已完成的 5D 第一版还没有进入“统一日历 + 周历拖拽 + 重复任务”形态；
  这些进入 Phase 5D.1。

### Phase 5D.1：统一日历、每日重复任务和开始久坐

完成状态：2026-07-06 已完成第一版。下一步应做真机验证和体验微调，
再回到首页、任务、提醒、同步等稳定化反馈。

更新背景：

- 用户希望任务页升级为类似日历的任务视图，并同时支持月历和周历。
- 周历要显示 7 天任务与时间块，且本阶段就做拖拽调整。
- 不新增单独“新建每日重复”入口；重复任务和普通任务用同一个新增任务流程，
  只是多一个“重复任务”选项，并选择重复范围时间。
- 不再叫“开始学习”；改为首页的“开始久坐”，用于手动开始久坐会话，
  到时提醒站起来活动。
- 账号、云端、国内部署和发布稳定化先后移，避免继续扩底层工程而忽略核心使用体验。

参考调研：

- 详细记录见
  `docs/architecture/open-source-calendar-recurring-focus-research-2026-07-06.md`。
- Super Productivity：重复任务配置 + 实例、错过日期补生成、休息提醒不依赖姿势传感器。
- Tasks.org：成熟 Android 任务重复、RRULE 和提醒重排；第一版不直接照搬完整 RRULE。
- Loop Habit Tracker：习惯是 habit + entry，不等同于每天生成任务；本项目暂不做习惯 streak。
- Vikunja：任务内 repeat_after / repeat_mode 简洁，但更偏“完成后重开同一任务”，
  本项目为了复盘和记忆解释，第一版更适合生成每日任务实例。

目标能力：

- 任务页升级为统一日历：
  - 月历：显示整月任务 / 时间块分布，点日期看当天详情；
  - 周历：显示连续 7 天任务与 `schedule_blocks`，支持拖拽调整。
- 统一日历的数据源包括：
  - 普通 `tasks`；
  - 每日重复任务生成的 `tasks` 实例；
  - 已有 `schedule_blocks`；
  - 首页“开始久坐”生成的久坐会话记录。
- 任务新增 / 编辑流程增加“重复任务”选项：
  - 第一版只支持每日重复；
  - 用户选择开始日期、结束日期或无结束日期、每天时间；
  - 生成当天和未来 7 天实例；
  - 同一规则同一天只能生成一个实例；
  - 删除某天实例后当天不自动补回；
  - 关闭规则后不再生成未来实例。
- 首页增加“开始久坐”：
  - 手动开始，不绑定任务；
  - 默认 60 分钟后提醒站起来活动；
  - 用户结束久坐后取消未触发提醒；
  - 不做姿势传感器、手表联动或自动识别坐躺。

第一版已落地：

- Drift schema 升级到 version 5：
  - `tasks` 增加 `recurrence_rule_id` / `recurrence_date`；
  - 新增 `recurring_task_rules`；
  - 新增 `sedentary_sessions`。
- 重复任务采用“规则 + 普通任务实例”：
  - 新增任务弹窗内提供“重复任务”开关；
  - 第一版只支持每日重复；
  - 创建规则后生成当天和未来 7 天任务实例；
  - 同一规则同一天不会重复生成；
  - 删除某天实例会记录 skipped date，当天不再自动补回。
- 任务页已改为统一任务日历：
  - 顶部支持“月历 / 周历”切换；
  - 月历展示每天任务、时间块和久坐会话数量；
  - 周历展示连续 7 天任务、已有 `schedule_blocks` 和久坐会话；
  - 周历支持长按拖拽任务或时间块到上午 / 下午 / 晚上时段；
  - 拖拽任务只更新任务时间；
  - 拖拽时间块只更新 block start/end，不改任务状态。
- 首页已增加“开始久坐”：
  - 手动开始 active sedentary session；
  - 默认 60 分钟后使用本地通知提醒活动；
  - 结束久坐会写入 `ended_at` 并取消未触发提醒；
  - 久坐会话会显示在统一日历里。
- 本地提醒扩展：
  - `TaskReminderRequest` 支持自定义 notification title/channel；
  - 新增 `SedentaryReminderCoordinator` 复用本地通知能力。
- 已补测试：
  - 重复规则生成唯一实例；
  - 删除某天重复实例后不自动补回；
  - 久坐会话开始和结束；
  - 久坐提醒 schedule/cancel key。

验证记录：

- `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs`
  通过，已更新 Drift 生成文件。
- `cd apps/mobile && dart analyze` 通过。
- `flutter analyze --no-pub`、`flutter test ...` 在当前 Codex 沙箱里启动后长时间无输出，
  已中断；后续真机验证前建议在本机终端重跑。

建议实现边界：

- 新增重复规则和实例关联能力，但不要把复杂 recurrence 塞进 `/parse`。
- 拖拽周历时，只更新任务时间或时间块时间；不得静默完成、取消、删除任务。
- 现有 `schedule_plans` / `schedule_blocks` 不废弃，统一日历应复用它们。
- 重复任务第一版仍是任务，不是习惯系统；连续打卡、习惯得分、streak 后置。
- 久坐会话第一版本地优先，账号和云同步后置。

后续验收重点：

- 月历能看到每天是否有任务 / 时间块。
- 周历能看到 7 天任务和时间块，并能拖拽调整。
- 普通任务新增流程中可以选择每日重复和范围时间。
- 每日重复任务不会重复生成同一天实例。
- 开始久坐后 60 分钟会提醒，结束后取消提醒。
- 以上能力不要求登录账号即可使用。

### Phase 5E：可控记忆管理增强

当前优先级：暂缓，先完成 Phase 5D.1。

目标：

- 让用户看懂哪些任务、状态、事件、画像和复盘 summary 会影响后续建议。

需要能力：

- 查看来源；
- 编辑；
- 删除；
- 归档；
- 必要时恢复；
- 显示某条记录是否参与建议。

这一步可以在统一日历、重复任务和开始久坐跑通后再做。

### 后置任务：账号、云端、国内部署和发布稳定化

更新日期：2026-07-06。

这些任务仍然重要，但当前不作为最近一轮优先主线。
之前 Phase 5A / 国内部署方向主要是为了验证线上功能、账号和真实使用链路；
现在先补核心使用体验，再回到线上稳定化。

后置建议顺序：

1. Phase 5D.1 完成后，再做首页、任务、提醒、同步等真机反馈修复。
2. 再评估是否继续推进国内版 API 部署。
3. 如继续推进，注册腾讯云或阿里云账号，优先购买便宜的国内轻量应用服务器。
4. 准备域名、备案和 HTTPS，把 `apps/api` 从 Vercel 复制部署到国内服务器。
5. 保留当前 Vercel + Supabase 配置作为海外版，不删除现有部署。
6. 国内版第一阶段只替换 `PARSER_BASE_URL`，先让 `/parse`、`/review`、`/plan`
   在中国大陆手机流量下可访问。
7. 国内版第二阶段再决定账号和数据库：
   - 短期可以继续使用 Supabase，验证国内网络可达性；
   - 如果登录和同步仍受网络影响，再迁移到国内 PostgreSQL / 云数据库和自建账号接口；
   - 不一次性重写全部账号、同步和数据库能力。
8. 国内版真实试用稳定后，再进入 Phase 5E 可控记忆管理增强。

国内版与海外版建议保持同一套 Flutter 代码，通过构建配置区分：

```text
海外版：Vercel API + Supabase
国内版：国内 HTTPS API + 国内数据库/账号（分阶段迁移）
```

发布前重点验收：

- 点击整理后首页今日行动立即更新；
- 自动保存任务有明确“已纳入行动”反馈；
- 任务页无需重启即可看到新任务；
- 三星 Android 可以申请通知权限并收到未来任务提醒；
- 登录和手动同步失败时能显示可判断的原因；
- 中国大陆手机流量无需 VPN 即可使用 `/parse`、`/review`、`/plan`。

## 4. AI 能力边界

近期保留四个实际入口：

```text
/parse
  结构化入库：任务、状态、事件、画像候选、普通回答。

/review
  每日复盘：日总结、任务处理建议、未解决事项、来源引用。

/plan
  可控时间规划：生成可编辑的时间块草稿，不静默改任务状态。

/memory
  记忆管理：查看、编辑、删除、恢复、解释来源。
```

`/coach` 暂不作为近期实现入口。未来如果要做目标对齐、学习进展、卡点和深度建议，再重新设计 `/coach`。

给初学者可以这样理解：

```text
/parse  问的是：这句话应该保存成什么？
/review 问的是：今天发生了什么，下一次处理类似任务要注意什么？
/plan   问的是：今天或本周这些任务可以怎么安排时间？
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
- 复杂重复提醒、多设备提醒和完整习惯 streak；每日重复任务已进入 Phase 5D.1；
- LLM rerank；
- 会员订阅和商业化。

## 6. 新 session 推荐入口

1. `AGENTS.md`：项目记忆和协作规则。
2. `docs/architecture/phase-5-task-map.md`：当前 Phase 5 主路线，先确认 Phase 5D.1。
3. `docs/architecture/open-source-calendar-recurring-focus-research-2026-07-06.md`：本轮开源项目调研和设计取舍。
4. `README.md`：当前能力和目录入口。
5. `apps/mobile/lib/app/app_shell.dart`：底部导航入口。
6. `apps/mobile/lib/features/home/home_screen.dart`：首页和未来“开始久坐”入口。
7. `apps/mobile/lib/features/memory/tasks_screen.dart`：当前任务页，统一日历改造入口。
8. `apps/mobile/lib/features/review/schedule_plan_screen.dart`：已有时间规划 / 类课表能力。
9. `apps/mobile/lib/data/local_db/tables.dart` 和 `apps/mobile/lib/data/local_db/app_database.dart`：任务、summary、schedule block 数据结构。
10. `apps/mobile/lib/features/reminders/task_reminder_scheduler.dart`：本地提醒能力。
11. `docs/architecture/current-verification.md`：最近验证记录。

## 7. 相关文档

- `docs/architecture/open-source-calendar-recurring-focus-research-2026-07-06.md`：统一日历、重复任务和久坐会话调研记录。
- `docs/architecture/summary-system-design.md`：summary / compressed context 设计背景。
- `docs/architecture/context-builder-design.md`：ContextBuilder 方向。
- `docs/architecture/phase-5-reflection-goals-evolution.md`：长期方向文档，注意其中学习目标 / 卡点路线已后置。
- `docs/architecture/task-update-resolution.md`：任务更新匹配边界。
- `docs/architecture/phase-4e-real-apk-trial.md`：真实 APK 试用链路。
