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
