我重新读了你仓库的最新内容。整体判断是：

> **项目已经从“技术骨架 MVP”进入了“真实手机试用后的可用性修正阶段”。**
> 下一阶段不应该再继续做抽象能力，而应该集中修复真实试用暴露出来的信任问题和日常使用问题。

---

# 一、当前项目进展判断

## 1. Phase 3 已经基本完成

最新文档显示，Phase 3 已经达到真实设备试用状态：Android 手机可以安装 debug APK，通过本地 API proxy 调用 DeepSeek，返回真实解析结果，并写入本地 SQLite。

当前已完成的能力包括：

* DeepSeek parser prompt、schema、sample set、smoke checks 覆盖 6 类 MVP item。
* 移动端 parser client 能调用 API proxy。
* extracted item 的确认、编辑、拒绝、自动保存、撤销/删除流程已存在。
* `task_update_resolution` ContextBuilder 已存在。
* 首页建议已经能基于任务、短期状态、长期画像生成规则解释。
* 记忆管理页能查看和删除任务、状态、生活事件、画像。
* 统一检查脚本 `scripts/check-all.sh` 已存在。

所以现在不是“还没做完 MVP”，而是：

> **MVP 已经可以真实试用，但还不够可信、不够顺手。**

---

## 2. D0 语义校准已经落地

你之前要求插入的 D0，现在已经不只是讨论稿，而是实际落地了。

仓库中已经有 `docs/architecture/chinese-semantic-classification-rules.md`，里面明确写了核心原则：

```text
How should this sentence be used in the future?
```

并且强调 parser 不能只按关键词分类，“记得”“提醒我”“回头”“有空”都只是弱信号，不是最终决策。

当前 D0 已经定义了：

* `task_create`
* `task_update`
* `short_term_state`
* `life_event`
* `profile_candidate`
* `general_answer`

还补了分类优先级：已有任务改变优先 `task_update`，未来行动优先 `task_create`，当前近期状态归 `short_term_state`，过去经验归 `life_event`，稳定偏好归 `profile_candidate`，普通问答归 `general_answer`。

parser prompt 里也已经加入了关键规则：不要只按关键词判断；未来安排、约定、预约、准备动作、提醒都应归为 `task_create`；社交娱乐安排如果是未来要参与，也应归为任务；“记得”要根据上下文判断是提醒任务还是过去记忆。

sample set 也已经补了很多 D0 样例，比如“晚上同学约我去网吧，我同意了”被要求归为 `task_create`，并禁止归为 `life_event` 和 `profile_candidate`。

---

## 3. 当前最新验证状态不错，但真实试用发现了关键问题

自动验证方面，最新 E2 记录是通过的：

* `flutter analyze` 通过。
* `flutter test` 105 个测试通过。
* `npm run typecheck` 通过。
* `npm test` 53 个测试通过。

但真实 Android 试用发现了更重要的问题：

1. “晚上/今晚/下午”这类同日隐含时间没有自然处理。
2. `task_update` 对取消类表达很敏感，比如“下午开会的事情取消了”失败，而“今下午不用去开会了”成功。
3. 明天任务会出现在今日行动里。
4. pending 待确认内容在新一轮整理后会从页面消失。
5. 日期和短期状态测试需要 debug 日期切换。
6. 删除记忆缺少确认。
7. 首页建议解释太挤，不够清楚。

这些都不是“规划层问题”，而是**真实使用信任问题**。

---

# 二、你目前真正存在的问题

我把你现在的问题分成 5 类。

---

## 问题 A：待确认内容不能丢

真实试用里最严重的问题是：

> 用户点击“整理”看到 pending items，还没确认，又输入新内容点击整理，前一批 pending 内容从页面消失。

这是 P0。

因为用户会觉得：

```text
我刚才让它整理出来的内容去哪了？
是不是丢了？
是不是我没确认就没了？
```

即使数据库里还在，UI 看不到也会造成“不可信”的感觉。

这应该是下一阶段第一优先级。

---

## 问题 B：时间语义和今日筛选不准

现在真实反馈里有两个时间相关问题：

1. “晚上”在中文自然语义里通常等于“今天晚上”，但系统没有自然处理。
2. 明天任务出现在今日行动列表里。

这两个问题会直接影响首页可信度。

如果用户明天的任务出现在“今日行动”里，他会觉得系统乱。
如果“今晚吃饭”不能自动变成今天晚上，他会觉得系统不懂中文生活语境。

当前移动端 `_inferTaskDue` 仍然只支持：

* 明天上午
* 明天下午
* 明天
* 今天

没有支持“今晚/晚上/下午/后天/下周一/这两天”等更自然表达。

这个要尽快修。

---

## 问题 C：task_update 匹配还太脆

D0 文档已经定义了 `task_update` 语义，ContextBuilder 也能提供 active task candidates。

但目前匹配逻辑仍比较简单：

* 先取 `target_task_title` 或 `target_text`
* 做 trim、去空格、小写
* 完全匹配或 contains 匹配
* “那个事/这个事/它”等泛指目标直接 noMatch

这导致“下午开会的事情取消了”这种真实中文表达容易失败。

真实反馈也明确说：

> 取消类表达、`不想去/不去了/不想做` 应该作为可能取消或意图冲突来处理。

---

## 问题 D：首页建议还需要等数据行为稳定后再打磨

首页现在能生成建议，也能把任务、状态、画像拼进 reason。代码里目前会把状态和画像用逗号拼接，再加到 reason 里。

真实反馈认为：

* 当前状态拼接太拥挤。
* 今日状态、当前状态、长期偏好看起来混在一起。
* 用户希望看到不止一个建议。
* 今日行动卡片最好能展开成日程。

但我不建议现在立刻大改首页 UI。因为如果 pending、时间、task_update 还不稳定，首页做得再漂亮也会显示错误数据。

---

## 问题 E：记忆删除安全性不足

真实反馈里提到：

> 删除记录时确认不够，所有删除动作都应有确认弹窗。

这个也很重要。因为这个产品的核心是个人记忆，删除行为必须让用户放心。

不过它的优先级略低于 pending 丢失、时间语义、task_update。

---

# 三、下一阶段建议命名

我建议下一阶段命名为：

> **Phase 4：真实试用信任修复阶段**

这个阶段目标不是扩展新功能，而是：

```text
不丢内容
不乱显示今天/明天
能更稳地理解任务取消/延期
允许用户安全删除
让首页解释更清楚
```

一句话：

> **先修信任，再做智能。**

---

# 四、Phase 4 任务地图

下面是我建议的新任务地图。

---

# Phase 4：真实试用信任修复阶段

```text
Phase 4
│
├── P0 信任底座
│   ├── F1 保留 pending 确认批次
│   ├── F2 删除操作确认弹窗
│   └── F3 Debug 日期切换能力
│
├── P1 时间与今日行动修复
│   ├── T1 同日隐含时间语义：晚上/今晚/下午
│   ├── T2 今天/明天/未来任务过滤修复
│   ├── T3 due_time_text + due_time 展示规则
│   └── T4 日期时间编辑器
│
├── P1 task_update 真实语义增强
│   ├── U1 取消/不想去/不用去/不去了 表达增强
│   ├── U2 目标匹配规则升级
│   ├── U3 模糊目标选择流程
│   └── U4 完成/取消任务可见化设计
│
├── P2 首页与行动区体验
│   ├── H1 首页建议解释分组
│   ├── H2 今日行动卡片可展开
│   ├── H3 多建议展示
│   └── H4 状态/画像引用更清晰
│
└── P3 后续能力预研
    ├── R1 重复任务/每天/偶尔提醒设计
    ├── R2 短期状态覆盖与失效策略
    ├── R3 life_event 未来自进化证据策略
    └── R4 长对话/重要建议页面预研
```

---

# 五、具体任务排序

## 第一段：必须立刻做，解决“信任底线”

### F1：保留 pending 确认批次

优先级：**P0**

用户连续整理多次时，前一次待确认内容不能从页面消失。真实反馈已经把这个列为 P0。

建议实现：

```text
输入 A → 生成 pending batch A
输入 B → 生成 pending batch B
页面显示最近 3 批待确认内容
用户可以逐条确认/修改/拒绝
```

不建议只保留内存状态，应该从数据库读取 pending extracted items。因为目前 extracted_items 本来就有 pending 状态，应该用它做持久化来源。

模型建议：

```text
Codex 5.5，高推理
```

原因：涉及状态流、数据库查询、UI 展示和测试，不是简单 UI 修改。

验收标准：

```text
1. 连续提交两次输入后，第一次 pending items 仍可见。
2. 至少显示最近 3 批 pending。
3. 已确认/拒绝的 item 从 pending 区移除。
4. flutter test 覆盖。
```

---

### F2：删除操作确认弹窗

优先级：**P0/P1 之间**

所有 task/state/life_event/profile 删除前都要确认。真实反馈明确要求删除动作需要确认。

模型建议：

```text
Claude Code + DeepSeek，中等
```

验收标准：

```text
1. 删除任务前弹确认。
2. 删除短期状态前弹确认。
3. 删除生活事件前弹确认。
4. 删除长期画像前弹确认。
5. 取消弹窗不删除。
6. 确认后才删除。
```

---

### F3：Debug 日期切换能力

优先级：**P1，但应该尽早做**

真实反馈说，短期状态和日期相关行为需要“明天验证”，不能真的等一天。

这个能力对后续 T1/T2 非常重要。

建议只在 debug/trial build 开启，不进正式用户设置。

模型建议：

```text
Codex 5.5，中高推理
```

验收标准：

```text
1. Debug 构建中可以切换当前日期。
2. today filtering 使用 debug date。
3. short_term_state 过期判断使用 debug date。
4. Release 默认使用真实 DateTime.now。
```

---

## 第二段：修时间系统和今日行动

### T1：同日隐含时间语义

优先级：**P1**

真实问题：

```text
今晚上要和同学吃烤鱼
```

用户没有说“今天”，但中文里“晚上”通常就是今天晚上。当前系统把它留 pending。

建议先支持：

```text
今晚
今晚上
晚上
下午
上午
中午
傍晚
```

规则：

```text
如果没有其他日期修饰，默认是今天对应时间段。
如果用户说“明天晚上”，则是明天晚上。
如果用户说“周五晚上”，则是周五晚上。
```

模型建议：

```text
Codex 5.5，高推理
```

因为这个涉及中文时间语义和测试。

---

### T2：今天/明天/未来任务过滤修复

优先级：**P1**

真实问题：

> 明天任务出现在今日行动列表。

现在 ContextBuilder 里 `todayTasks` 的逻辑是：

```dart
if (task.dueTime == null || _isSameDay(task.dueTime!, now)) task
```

也就是说，没有 dueTime 的任务也会被归入 todayTasks。

这可能是一个问题。没有明确日期的任务不一定是今天任务。

建议改成：

```text
todayTasks：只包含 dueTime 是今天的任务。
unscheduledTasks：单独分组。
nextSevenDaysTasks：未来 7 天任务。
overdueTasks：逾期任务。
```

模型建议：

```text
Codex 5.5，高推理
```

原因：会影响首页、ContextBuilder、测试和建议排序。

---

### T3：due_time_text + due_time 展示规则

优先级：**P1**

真实反馈说，未来任务和 reminder-like task 时间显示太模糊，需要保存具体日期，同时保留原始时间文本。

建议：

```text
有 due_time：显示具体日期 + 原文时间
无 due_time 但有 due_time_text：显示“时间待明确：原文”
无时间：显示“未设时间”
```

例如：

```text
今天晚上 20:00｜原文：晚上
明天上午 09:00｜原文：明天上午
时间待明确｜原文：回头
```

模型建议：

```text
Claude Code + DeepSeek，中等
```

---

### T4：日期时间编辑器

优先级：**P1，但排在 T1/T2 后**

真实反馈说，任务 deadline 编辑现在是手填文本，不适合未来提醒。

建议先做：

```text
日期 picker
时间 picker
清除时间
保留 due_time_text
```

模型建议：

```text
Claude Code + DeepSeek，中高
Codex 审查
```

---

## 第三段：task_update 真实语义增强

### U1：取消类表达增强

优先级：**P1**

真实问题：

```text
下午开会的事情取消了
```

没有取消成功；但：

```text
今下午不用去开会了
```

成功。

要扩展表达：

```text
取消了
不用去了
不去了
不想去了
不想做了
先不做了
不用开了
不用处理了
改天再说
```

但注意：

```text
不想去
```

不一定等于取消，可能是意图冲突。比如：

```text
今天好累，健身不想去了
```

应该至少识别出“可能取消/延期/降低强度”的 task_update，并让用户确认。

模型建议：

```text
Codex 5.5，高推理
```

---

### U2：目标匹配规则升级

优先级：**P1**

当前匹配只做 exact / contains。

下一步建议加：

```text
1. 去掉“的事情/这个事/这件事”等噪声词。
2. 动词归一：开会/去开会/会议。
3. 时间辅助匹配：下午开会 → 今天下午开会。
4. 关键词 token 匹配：王总、健身、客户、PPT。
5. 如果唯一候选高匹配 → ready。
6. 多候选 → needsSelection。
7. 无候选 → noMatch。
```

模型建议：

```text
Codex 5.5，高推理
```

---

### U3：模糊目标选择流程

优先级：**P1/P2**

目前泛指目标如“那个事/这个事/它”会直接 noMatch。

但你之前判断过：用户任务不会特别多时，“王总那个事”大概率能匹配；完全泛指“那个事搞定了”才应该选择。

建议：

```text
那个事搞定了 → 如果今日只有 1 个 active task，可询问是否是它
王总那个事 → 用“王总”匹配候选
这个健身 → 用“健身”匹配候选
```

不要直接都 noMatch。

模型建议：

```text
Codex 5.5，高推理
```

---

### U4：完成/取消任务可见化设计

优先级：**P2，先设计，后实现**

你之前提出：完成/取消不要直接从任务栏消失，而是划线、标注状态、可撤销。D0 guide 也已经记录“完成/取消后的划线可见、状态标签、来源原文、撤销入口”作为后续实现计划。

但这个可能涉及数据模型：

```text
record_status: confirmed/deleted/archived
task_status: active/completed/cancelled
```

D0 guide 也提醒了 record_status 和任务业务状态混用的风险。

我建议先写设计文档，再改表。

模型建议：

```text
Codex 5.5，高推理
```

---

## 第四段：首页和今日行动体验

这个阶段放在数据行为稳定之后。

### H1：首页建议解释分组

当前 reason 把任务、当前状态、长期偏好拼在一句里。

建议改成分组：

```text
为什么推荐：
任务依据：
- 今天 18:00 和同学吃烤鱼

当前状态：
- 今天有点累

长期偏好：
- 不喜欢太频繁提醒
```

模型建议：

```text
Claude Code + DeepSeek，中等
```

---

### H2：今日行动卡片可展开

真实反馈希望点击今日行动区域，展开成今日任务安排。

建议：

```text
今日行动
- 18:00 和同学吃烤鱼
- 20:00 拉伸
- 未设时间：整理资料
```

模型建议：

```text
Claude Code + DeepSeek，中等
```

---

### H3：多建议展示

真实反馈希望不止一个 AI suggestion。

现在代码里其实可以生成最多 3 个 suggestions，但 UI 可能没有充分展示。HomeSuggestionService 使用 `sortedTasks.take(3)`。

这里主要是 UI 呈现问题。

模型建议：

```text
Claude Code + DeepSeek，中等
```

---

# 六、下一阶段时间段安排

我建议按 4 个时间段推进。

---

## 时间段 1：Phase 4A，信任底线修复

目标：

```text
用户的数据不能丢，删除不能误删，测试日期可控。
```

任务：

1. F1 pending confirmation batches
2. F2 删除确认弹窗
3. F3 debug 日期切换

优先级：

```text
最高
```

推荐模型：

```text
F1：Codex 5.5，高推理
F2：Claude Code + DeepSeek，中等
F3：Codex 5.5，中高推理
```

完成标准：

```text
./scripts/check-all.sh 通过
真实手机上连续整理不会丢 pending
删除必须二次确认
可以切日期测试明天/过期状态
```

---

## 时间段 2：Phase 4B，时间和今日行动修复

目标：

```text
今天、明天、晚上、未来任务不再乱。
```

任务：

1. T1 同日隐含时间语义
2. T2 今日/明天过滤修复
3. T3 时间展示规则
4. T4 date/time picker

推荐模型：

```text
T1/T2：Codex 5.5，高推理
T3/T4：Claude Code + DeepSeek，中高
```

完成标准：

```text
“晚上吃烤鱼”成为今天晚上任务
明天任务不出现在今日行动
无时间任务进入未安排分组
任务编辑可以用日期时间选择器
```

---

## 时间段 3：Phase 4C，task_update 真实表达增强

目标：

```text
取消、完成、延期不再依赖固定说法。
```

任务：

1. U1 取消类表达增强
2. U2 目标匹配升级
3. U3 模糊目标选择流程
4. U4 完成/取消可见化设计文档

推荐模型：

```text
U1/U2/U3/U4：Codex 5.5，高推理
部分 UI 可交 Claude Code + DeepSeek
```

完成标准：

```text
“下午开会的事情取消了”能匹配任务
“今天好累，健身不想去了”能生成 task_update + short_term_state
多个候选时让用户选
无候选不误改
完成/取消可见化有明确设计
```

---

## 时间段 4：Phase 4D，首页体验和试用闭环

目标：

```text
用户看得懂首页为什么这么建议，也能继续真实试用。
```

任务：

1. H1 首页解释分组
2. H2 今日行动可展开
3. H3 多建议展示
4. 重新整理 Phase 4 verification
5. 再次 Android 真机试用

推荐模型：

```text
Claude Code + DeepSeek，中等
Codex 做最终审查
```

完成标准：

```text
首页解释不拥挤
今日任务能展开
建议能显示 1-3 条
真实手机试用问题明显减少
```

---

# 七、我建议你现在立刻交给 Codex 的任务

最建议先做这个：

```md
# Phase 4A-F1：保留 pending 确认批次

当前仓库已经完成 Phase 3 D0/D1/D2/E1/E2，并完成 Samsung Android 真实 API 试用。真实试用反馈中，最高优先级问题是：用户点击“整理”看到 pending items 后，如果未确认又输入新内容再次整理，上一批待确认内容会从页面消失。这会造成用户认为数据丢失，是 P0 信任问题。

请先阅读：
1. AGENTS.md
2. docs/architecture/current-verification.md
3. docs/architecture/phase-3-real-trial-feedback.md
4. docs/architecture/phase-3-verification.md
5. apps/mobile/lib/features/input/input_screen.dart
6. apps/mobile/lib/features/extracted_items/extracted_items_controller.dart
7. apps/mobile/lib/data/local_db/app_database.dart
8. apps/mobile/lib/data/local_db/tables.dart

任务目标：
实现 pending confirmation batches 持久展示。

要求：
1. 连续提交多次输入后，之前未确认的 pending items 不能从 UI 消失。
2. 至少显示最近 3 批仍需确认的 pending extracted items。
3. 每一批应能显示来源时间或简短批次信息。
4. 用户可以继续对旧 pending item 执行确认、编辑、拒绝。
5. 已确认/拒绝/删除的 item 应从待确认区域移除。
6. 不改变 6 类 MVP item type。
7. 不引入云同步、向量检索、完整 Agent。
8. 优先利用现有 extracted_items 表和 pending 状态；如确需新增字段，先说明理由。
9. 补充 widget/unit tests，覆盖连续两次整理后旧 pending 仍可见。
10. 完成后运行：
   - cd apps/mobile && flutter analyze
   - cd apps/mobile && flutter test
   - 如影响 API，再运行 cd apps/api && npm run typecheck && npm test

验收标准：
- 输入 A，出现 A 的待确认卡片。
- 不确认 A，继续输入 B。
- 页面同时能看到 A 和 B 的待确认卡片，至少最近 3 批。
- 确认/拒绝 A 不影响 B。
- 重新进入页面后 pending items 仍能从数据库恢复。
```

---

# 八、我的总体建议

你下一阶段不要再把重点放在“更智能”上，而是放在：

```text
更可信
更稳定
更符合日常语言
更不容易误删/漏提醒
```

当前最推荐顺序是：

```text
1. pending 批次保留
2. 删除确认
3. debug 日期切换
4. 晚上/今晚/下午等同日时间语义
5. 今日/明天任务过滤
6. task_update 取消表达和匹配增强
7. 日期时间编辑器
8. 首页解释分组和今日行动展开
```

这条路线最稳。它能把你的 App 从“能跑、能解析”推进到“我愿意连续用几天试试”。
