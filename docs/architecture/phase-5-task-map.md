# Phase 5 任务地图

日期：2026-06-17

状态：规划地图。本文件记录 Phase 5 及其前置工作的建议执行顺序，不代表这些内容要一次性全部实现。

## 1. 当前站位

Phase 4A-4E 已经完成真实 Android 试用后的主要信任修复：

- 待确认批次不会因为连续整理而丢失；
- 删除任务、状态、事件、画像前有二次确认；
- 今天 / 明天 / 未来 / 未安排任务分组更清楚；
- `task_update` 对取消、完成、目标匹配的理解更稳；
- 首页 AI 建议和今日行动可以展开，并解释依据；
- 任务已有 `task_status: active / completed / cancelled`；
- Android debug APK + 本地 API proxy + DeepSeek 真机试用链路已文档化。

项目已经进入 Phase 5 方向，但 2026-06-17 的最新决策是：

```text
不要先做大而全知识库。
先增强 AI 对用户输入文字的精细识别。
再实现本地任务提醒。
等解析和提醒稳定后，再进入复盘、目标对齐和可控自进化。
```

## 2. Phase 5 主目标

Phase 5 的核心不是“加更多智能功能”，而是让 App 从“能记任务和状态”升级为：

```text
能帮助用户复盘发生了什么，
知道用户确认过的学习目标，
记录真实进展和卡点，
然后给出下一步建议。
```

推荐产品闭环：

```text
用户记录任务、状态、事件、想法
→ AI 解析成可见的结构化记录
→ 用户确认 / 修改 / 删除重要记录
→ App 生成有来源依据的每日复盘
→ 用户确认学习目标、学习进展、卡点
→ App 给出 1-3 个下一步建议
→ 已确认的总结、目标、进展继续影响后续建议
```

这里的“可控自进化”不是 AI 自动替用户改人生规划，而是：用户确认过的目标、进展、偏好和总结越多，后续建议越贴近用户。

## 3. 推荐执行顺序

### Phase 5 前置 A：AI 文字解析准确性

完成状态：已于 2026-06-17 完成第一轮增强。

目标：

- 让 `/parse` 更准确理解真实中文输入，尤其是语音化表达、废话填充、取消、延期、任务创建、状态、事件、模糊时间和混合输入。

关键文件：

- `apps/api/src/services/parserPrompt.ts`
- `apps/api/src/services/parserSampleSet.ts`
- `apps/api/test/`
- `apps/mobile/lib/features/extracted_items/task_due_inference.dart`
- `apps/mobile/lib/features/extracted_items/task_update_matcher.dart`

边界：

- `/parse` 继续只做结构化入库；
- 不把复盘、教练、知识库、个人问答塞进 `/parse`；
- 先补真实失败样例和测试，再调整 prompt 或本地兜底规则。

完成标准：

- 测试样例覆盖任务创建、任务更新、取消、延期、状态、事件、长期画像候选、普通问答和模糊时间边界。

本轮完成内容：

- API prompt 增加语音化 / 口语化输入、混合意图、可靠时间和歧义时间边界。
- Parser sample set 增加 Phase 5 真实中文样例：语音化任务、问题夹带任务、裸“七点”歧义、口语取消、明确延期、模糊延期、状态和事件混合。
- Smoke 评估增加裸时钟歧义检查，避免把“明天七点”硬造为具体 `due_time_iso`。
- 移动端 `task_due_inference.dart` 支持“后天 / 大后天 / 下周一下午三点”等安全兜底，同时不为“明天七点”这类缺早晚表达乱造时间。
- 移动端 `task_update_matcher.dart` 增强口语取消和延期噪声清洗。
- 新增移动端独立测试覆盖时间兜底和任务更新匹配。

### Phase 5 前置 B：本地任务提醒

完成状态：已于 2026-06-18 完成第一轮系统通知层。

目标：

- 基于已确认、未完成、未取消、带 `dueTime` 的任务，增加本地提醒能力。

第一版只做：

- 一次性本地提醒；
- 通知权限处理；
- 任务确认或编辑时间后安排提醒；
- 任务完成、取消、删除或清除时间后取消提醒；
- 如果实现成本可控，在任务 UI 上显示提醒状态。

暂时不做：

- 重复提醒；
- 云端提醒；
- 多设备同步；
- 服务端定时任务；
- 很复杂的提前量和规则系统。

完成标准：

- 一个有明确时间的已确认任务能触发本地提醒；任务状态变化时，提醒能安全取消或更新。

本轮完成内容：

- 新增 `TaskReminderScheduler` / `TaskReminderCoordinator`，把提醒安排和取消从任务业务逻辑中抽象出来。
- 任务自动保存、手动确认、任务更新、撤销自动保存、编辑自动保存、任务管理页编辑 / 删除都接入提醒同步入口。
- 接入成熟插件 `flutter_local_notifications`，默认实现改为系统本地通知。
- App 启动时初始化通知插件和本地时区；第一次安排提醒时请求 Android / iOS 通知权限。
- Android 已配置 `POST_NOTIFICATIONS`、`VIBRATE`、`RECEIVE_BOOT_COMPLETED`、定时通知 receiver、启动后恢复 receiver、desugaring 和通知图标。
- iOS 已配置 `UNUserNotificationCenter` delegate，支持前台通知回调基础接入。
- Android 调度模式使用 `inexactAllowWhileIdle`，先避开精确闹钟权限和审核复杂度。
- 完成 / 取消 / 删除 / 清空时间 / 过期时间会取消提醒；active 且未来 `dueTime` 的任务会安排提醒。
- 新增测试覆盖提醒调度规则、自动保存任务安排提醒、完成任务取消提醒。
- 已验证：`flutter build ios --simulator --debug --no-codesign` 和 `flutter build apk --debug` 通过。

### Phase 5A：每日复盘总结

目标：

- 根据当天可见记录生成简洁复盘。

输入来源：

- 今日任务；
- 已完成 / 已取消任务；
- 短期状态；
- 生活事件；
- 用户补充的复盘文字。

输出：

- 可编辑的每日 summary；
- 有来源记录或来源分组；
- 当依据不足时明确说明不确定。

边界：

- 新增 `/review` 类能力，不继续压给 `/parse`；
- 复盘 summary 必须可见、可编辑、可删除、可重新生成；
- 单日 summary 不能自动变成长期画像。

### Phase 5B：显式学习目标

目标：

- 让用户保存确认过的学习目标，例如 Flutter、UI 设计、销售、写作、AI 编程协作。

边界：

- 学习目标必须由用户明确确认；
- 不能从一句随口表达自动推断长期目标；
- 目标要支持编辑、归档、删除。

### Phase 5C：学习进展与卡点

目标：

- 从复盘或用户输入中提取当天学习进展和卡点。

例子：

- “今天终于理解了 Riverpod provider 是怎么给页面供数据的。”
- “我还是搞不懂 API route 和前端请求的边界。”

边界：

- 只有高置信时才自动关联到已确认学习目标；
- 不确定时让用户确认；
- 进展和卡点是证据，不是永久性人格标签。

### Phase 5D：下一步建议

目标：

- 根据已确认目标、近期进展、卡点、任务和复盘 summary，给出 1-3 个小而具体的下一步建议。

边界：

- 建议要说明依据；
- 不自动创建任务，除非用户选择“加入任务”；
- 不假装知道来源记录之外的信息。

### Phase 5E：可控记忆管理增强

目标：

- 让用户看懂哪些记忆、summary、学习目标、画像会影响后续建议。

需要能力：

- 查看来源；
- 编辑；
- 删除；
- 归档；
- 必要时恢复；
- 显示某条记录是否参与建议。

## 4. AI 能力边界

推荐后续拆成四类入口：

```text
/parse
  结构化入库：任务、状态、事件、画像候选、普通回答。

/review
  复盘总结：日总结、周总结，并保留来源依据。

/coach
  目标对齐：结合目标、进展、卡点，给下一步建议。

/memory
  记忆管理：查看、编辑、删除、恢复、解释来源。
```

给初学者可以这样理解：

```text
/parse  问的是：这句话应该保存成什么？
/review 问的是：今天发生了什么？
/coach  问的是：接下来最好做什么？
/memory 问的是：App 现在记住了什么，我能不能控制？
```

## 5. 暂不进入的范围

这些等 Phase 5 小闭环跑稳后再考虑：

- 完整电脑端客户端；
- 通用知识库；
- 向量检索；
- 自动长期画像进化；
- 广泛个人问答；
- 自主 Agent 规划；
- 云同步；
- 重复提醒和多设备提醒；
- LLM rerank。

## 6. 相关文档

- `docs/architecture/phase-5-reflection-goals-evolution.md`：Phase 5 长期产品与架构方向。
- `docs/architecture/summary-system-design.md`：summary / compressed context 设计背景。
- `docs/architecture/context-builder-design.md`：ContextBuilder 方向。
- `docs/architecture/task-update-resolution.md`：任务更新匹配边界。
- `docs/architecture/phase-4e-real-apk-trial.md`：真实 APK 试用链路。
