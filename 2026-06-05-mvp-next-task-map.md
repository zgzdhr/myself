# AI Personal Memory Action System：Phase 4 任务地图

## 0. 当前共识

项目已经不是空项目，也不是“从 0 到 6 阶段搭 MVP”的状态。Flutter App、API proxy、本地 SQLite、DeepSeek 解析、待确认卡片、自动保存、首页建议、记忆管理、ContextBuilder、Phase 3 真机试用都已经存在。

当前阶段是：

> Phase 4：真实试用信任修复阶段。

Phase 4 的目标不是继续扩“智能”，而是先修真实试用暴露出来的信任问题：

```text
不丢内容
不乱显示今天/明天
更稳地理解任务取消/延期
删除和编辑让用户放心
首页解释更清楚
```

## 1. Phase 4A：信任底座修复，已完成

提交：

```text
c389778 feat: complete phase 4A trust fixes
```

已完成：

- F1：保留最近 3 批 pending 待确认内容。
- F2：任务、短期状态、生活事件、长期画像删除前增加二次确认。
- F3：Debug 构建新增测试日期切换。

验证：

- `cd apps/mobile && flutter analyze`：通过。
- `cd apps/mobile && flutter test`：通过，108 个测试通过。

后续不要重复实现 Phase 4A，除非是基于真实试用继续修 bug。

## 2. Phase 4B：时间语义与今日行动修复，已完成

提交：

```text
f62bba1 feat: complete phase 4B time fixes
```

已完成：

- T0：Time Reference Contract。移动端解析请求传 `current_time_iso`，API schema 和 parser prompt 使用当前时间解释“今天 / 明天 / 今晚”等相对日期。
- T0 扩展：预留可选 `location_context`，默认不上传地点；未来用户授权定位后可作为解析上下文，prompt 明确没有地点时不得猜测位置。
- T1：同日隐含时间语义，支持 `今晚`、`今晚上`、`晚上`、`上午`、`下午`、`中午`、`傍晚` 等。
- T2：今天 / 明天 / 未来任务过滤修复，ContextBuilder 拆分 `overdueTasks`、`todayTasks`、`nextSevenDaysTasks`、`unscheduledTasks`。
- T3：任务时间展示规则，有具体时间显示日期时间和原文，模糊时间显示“时间待明确”，无时间显示“未设时间”。
- T4：任务编辑支持选择日期、选择时间和清除时间。

验证：

- `cd apps/mobile && flutter analyze`：通过。
- `cd apps/mobile && flutter test`：通过，118 个测试。
- `cd apps/api && npm run typecheck`：通过。
- `cd apps/api && node --test --import tsx test/deepseekParser.test.ts test/parseResultSchema.test.ts test/parserPrompt.test.ts`：通过，28 个测试。

已知缺口：

- `apps/api/test/privacyLogging.test.ts` 单独运行会挂住。它负责验证 API 错误日志不泄露用户原文，后续需要单独排查 server / fetch 生命周期。

## 2.5 Phase 4B Hotfix：时间精度与确认编辑补丁，当前执行

来源：2026-06-08 Phase 4B Debug APK 真机回归反馈。

目标：

```text
具体几点优先于上午/下午/晚上默认值
逾期任务要可见
待确认任务编辑能补日期时间
4C 目标识别问题先记录，随后进入 4C 正式处理
```

### 4B-H1：明确时间点优先于时间段默认值

真实问题：

- `今晚上9点我要出去玩` 被保存成 19:00。
- `下午1:20我要出去` 被保存成 14:00。

技术路径：

- 在 `apps/mobile/lib/features/extracted_items/extracted_items_controller.dart` 中先解析明确时间点，再应用时间段默认值。
- 支持中文日常表达：
  - `9点`
  - `九点`
  - `9点半`
  - `9:30`
  - `9：30`
  - `下午1:20`
  - `晚上9点`
- 优先级：

```text
明确日期 + 明确时间 > 明确时间 > 时间段默认值 > 仅今天 / 明天默认值
```

- 上午 / 下午 / 晚上修正 12 小时制：
  - `下午1:20` -> 13:20
  - `晚上9点` -> 21:00
  - `上午9点` -> 09:00

### 4B-H2：时间段默认提醒点调整

用户确认的默认时间点：

- 上午：09:00
- 中午：11:00
- 下午：14:00
- 傍晚：18:00
- 晚上 / 今晚 / 今晚上：18:00
- 明天：09:00
- 今天：当前小时，后续可再优化

解释：这些默认值是“提醒友好”的保守时间，不是假设事件真实发生时间。例如午饭可能 12 点，但 11 点提醒更合理。

### 4B-H3：逾期任务可见化

真实问题：

- 当 `task.dueTime < now` 时，任务应显示“已逾期”，而不是只显示日期时间。

技术路径：

- 不把数据库 `status` 改成逾期；逾期是动态状态，由当前时间和 `dueTime` 计算。
- 在任务时间 formatter 或任务卡片中根据 `dueTime < now` 显示：

```text
已逾期｜6月8日 14:00｜原文：下午
```

- 首页 / ContextBuilder 已有 `overdueTasks` 分组，后续 Phase 4D 可进一步把逾期任务独立展示。

### 4B-H4：待确认任务编辑增加日期 / 时间选择

真实问题：

- 无确定时间的 `task_create` 通常需要确认，但待确认卡片点“编辑”只支持标题和内容，不能补日期 / 时间。

技术路径：

- 扩展 `EditExtractedItemSheet` 的返回值，使 `task_create` 可带 `dueTimeText` 和 `dueTime`。
- 只有 `task_create` 显示日期选择、时间选择和清除时间。
- `profile_candidate` 不显示日期时间字段。
- `short_term_state` / `life_event` 先保留标题 / 内容编辑，不强制加时间。
- 时间字段允许为空，不能强制用户填写。
- `ExtractedItemsController.confirmExtractedItem` 和 `editAutoSavedExtractedItem` 优先使用编辑 sheet 返回的 `dueTime / dueTimeText`；没有编辑时间时再走 `_inferTaskDue`。

### 4B-H5：4C 目标识别问题先记录

真实问题：

```text
明天我要去参加高考
参加高考那个事取消了
```

期望：识别为取消“参加高考”任务。

当前问题：模型 / prompt 可能把目标抽成“那个事”，导致匹配失败。

归属：Phase 4C 正式处理，不在 Hotfix 里强行完成。

技术方向：

- Prompt：要求 `target_text` 优先保留实义目标，例如“参加高考”，不要只输出“那个事 / 这个事”。
- App：当 AI 仍返回“那个事”时，结合当前输入全文、已有任务、时间和关键词做匹配，而不是只用 `target_text`。

### 4B-T1：同日隐含时间语义

真实问题：

```text
今晚上要和同学吃烤鱼
```

用户没有显式说“今天”，但中文日常语义里，“晚上 / 今晚 / 今晚上”在没有其他日期修饰时通常指今天晚上。

目标：

- 支持 `今晚`、`今晚上`、`晚上`、`上午`、`下午`、`中午`、`傍晚`。
- 无其他日期修饰时默认归到今天对应时间段。
- 有明确日期修饰时尊重明确日期，例如 `明天晚上`、`周五下午`。
- 不确定表达继续保留 `due_time_text`，不要乱造精确 ISO 时间。

建议涉及文件：

- `apps/mobile/lib/features/extracted_items/extracted_items_controller.dart`
- `apps/api/src/services/parserPrompt.ts`
- `apps/api/src/services/parserSampleSet.ts`
- `docs/architecture/chinese-semantic-classification-rules.md`

验收样例：

- “今晚上要和同学吃烤鱼”应创建今天晚上的任务或安排。
- “晚上和同学吃烤鱼”在无其他日期时优先按今天晚上处理。
- “明天晚上和同学吃烤鱼”不能被错误归到今天。

### 4B-T2：今天 / 明天 / 未来任务过滤修复

真实问题：

> 明天任务被列入今日行动。

目标：

- `todayTasks` 只包含 due time 是今天的任务。
- `overdueTasks` 单独表示逾期任务。
- `upcomingTasks` 表示未来 7 天任务。
- `unscheduledTasks` 单独表示未设时间任务，不默认塞进今日任务。
- 首页建议和今日行动文案要基于这些分组。

建议涉及文件：

- `apps/mobile/lib/features/context/context_builder.dart`
- `apps/mobile/lib/features/home/home_suggestion_service.dart`
- `apps/mobile/lib/features/home/home_screen.dart`
- `apps/mobile/test/features/context/context_builder_test.dart`
- `apps/mobile/test/widget_test.dart`

验收样例：

- 明天任务不出现在今日行动里。
- 无 due time 的任务不默认算作今日任务。
- Debug 日期切换到明天后，明天任务应进入对应日期的今日任务。

### 4B-T3：due_time_text + due_time 展示规则

真实问题：

任务时间展示太空，未来提醒需要具体到日期和时间。

目标：

- 有 `due_time`：显示具体日期 / 时间。
- 有 `due_time_text`：保留原始表达，辅助用户理解 AI 为什么这样推断。
- 无具体时间但有原文时间：显示“时间待明确”。
- 无时间：显示“未设时间”或进入未安排分组。

示例：

```text
今天 20:00｜原文：晚上
明天上午｜原文：明天上午
时间待明确｜原文：回头
未设时间
```

### 4B-T4：日期时间编辑器

真实问题：

任务编辑里的截止日期现在偏手填，不适合真实提醒场景。

目标：

- 任务编辑支持日期选择。
- 支持时间选择。
- 支持清除时间。
- 保留 `due_time_text`，不要丢失用户原始表达。

边界：

- 已完成日期选择、时间选择和清除时间入口。
- 完整提醒、重复提醒、提前提醒仍后置。

## 3. Phase 4C：task_update 真实语义增强，当前下一步

执行状态（2026-06-08）：

- 已补 parser prompt 和 sample set：要求取消类表达识别为 `task_update`，并优先抽取同一句里的实义目标，例如 `参加高考`、`下午开会`、`健身`。
- 已补 App 端兜底匹配：即使 AI 返回 `那个事`，也会结合 `source_text` 清洗噪声词，再匹配现有 active task。
- 已覆盖真实失败样例：
  - `参加高考那个事取消了` -> 匹配 `参加高考`。
  - `下午开会的事情取消了` -> 匹配 `今天下午开会`。
  - `今天好累，健身不想去了` -> 可匹配 `今天下午去健身`；长期目标冲突分析仍后置。
- 已验证：移动端确认流测试、移动端全量测试、API prompt/sample 定向测试和 API typecheck 通过。
- 未完成：完成 / 取消任务的业务状态可见化仍使用当前 MVP 临时策略，后续应引入 `task_status: active / completed / cancelled`，不要长期混用 `record_status`。

### 4C-U1：取消类表达增强

真实问题：

```text
下午开会的事情取消了
```

没有取消成功，但：

```text
今下午不用去开会了
```

可以成功。

目标：

- 扩展取消 / 放弃 / 暂停表达：
  - `取消了`
  - `不用去了`
  - `不去了`
  - `不想去了`
  - `不想做了`
  - `先不做了`
  - `不用开了`
  - `改天再说`
- `task_update` 不应自动静默生效，仍要让用户确认。

### 4C-U2：目标匹配规则升级

目标：

- 去掉“的事情 / 这个事 / 那个事 / 这件事”等噪声词。
- 做简单动作归一，例如 `开会 / 去开会 / 会议`。
- 用时间辅助匹配，例如 `下午开会` 匹配今天下午的开会任务。
- 用关键词 token 匹配，例如 `王总`、`健身`、`客户`、`PPT`。
- 唯一高置信候选进入确认。
- 多候选进入选择。
- 无候选提示未找到，不改正式任务。

### 4C-U3：当前任务与长期目标冲突分析，先记录后实现

例子：

```text
今天好累，健身不想去了
```

不能只机械取消。未来如果用户已确认长期目标是保持健康或好身材，系统应提示冲突，让用户选择：

- 继续去。
- 降低强度。
- 改期。
- 取消。

边界：

- Phase 4C 可以先识别为“可能取消 / 需要确认”。
- 不做完整长期目标推理。
- 未确认的 `profile_candidate` 不能当作事实。

### 4C-U4：完成 / 取消任务可见化设计

目标：

- 完成或取消后，不要从用户视野里突然消失。
- 更合适的体验是划线、灰色、状态标签、来源原文和撤销入口。
- 中期考虑引入 `task_status: active / completed / cancelled`，不要长期混用 `record_status` 表达任务业务状态。

## 4. Phase 4D：首页与行动区体验

目标：

- AI 建议区域可展开。
- 展开后看到 1-3 条建议及依据。
- 今日行动区域可展开，看到当天任务安排。
- 状态、今日任务、长期偏好分组展示，不再全部用逗号挤在一起。

建议顺序：

1. 首页建议解释分组。
2. 今日行动卡片可展开。
3. 多建议展示。
4. 状态 / 画像引用更清晰。

边界：

- 先等 Phase 4B/4C 的数据行为更稳定，再大改首页。
- 不接 LLM rerank。
- 不做完整 Agent。

## 5. Phase 4E：试用版和 APK 链路

目标：

- 继续支持 Android 真机 APK 真实测试。
- 明确 Debug / Release 网络配置区别。
- 记录本地 API proxy、LAN 地址、DeepSeek API 代理、手机安装的配合方式。

边界：

- Debug APK 可以连接本地 API proxy。
- DeepSeek API Key 不能放进移动端客户端。
- 正式分发、账号系统、云同步、端到端加密后置。

## 6. 后置能力

这些能力暂不进入 Phase 4 主线：

- 完整 AI Agent。
- 向量检索。
- 自动长期画像进化。
- 行为模式自动总结。
- 复杂日 / 周 / 月复盘。
- 云同步。
- 语音识别和语音回复。
- 商业化订阅。

它们不是永远不做，而是要等真实试用证明基础链路可信后再做。
