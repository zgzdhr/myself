# Phase 3 D0 中文语义边界校准指导文件

> 本文件由 `2026-06-07-phase3_d0.md`、`2026-06-07-phase3_d0_reward.md`、`2026-06-07-phase3_d0_update.md` 整理而来，是 D0 当前执行入口。原始 3 个文件保留为讨论原稿。

## 1. D0 目标

Phase 3 C 阶段已经完成。继续 D1 / D2 / E 之前，先插入 D0：中文语义边界校准。

D0 要解决的核心问题不是“多加几个关键词”，而是把 App 的语义判断从关键词匹配升级为：

```text
这句话未来应该怎么被使用？
```

D0 当前只做：

- 明确 6 类 item 的中文语义边界。
- 更新 parser prompt 的分类原则。
- 扩展 parser sample set 和 smoke 检查。
- 规划 `task_update`、`short_term_state`、`life_event` 的后续策略。

D0 当前不做：

- 提醒系统。
- 已完成 / 已取消任务自动清理设置。
- 延期任务双提醒。
- 自动长期画像进化。
- `life_event` 自动总结为 `profile_candidate`。
- 深度建议 / 长对话页面。
- `general_answer` 个性化上下文回答。
- 向量检索、云同步、完整 AI Agent。

## 2. 总分类原则

分类不能只看关键词。比如“记得提醒我给客户发消息”可能是任务，但“我记得我之前读过这本书”不是任务，而是回忆。

优先级建议：

```text
1. 改变已有任务 -> task_update
2. 未来要做 / 已答应 / 预约 / 计划 / 提醒 -> task_create
3. 当前、今天、近期身体/情绪/精力/位置/可用性 -> short_term_state
4. 已发生事件、经验、教训、观察 -> life_event
5. 长期偏好、习惯、背景、工作方式 -> profile_candidate
6. 普通知识问答、搜索、闲聊、建议请求 -> general_answer
```

同一条输入可以拆成多个 item，不能强行只选一个。

## 3. 六类 item 边界

### `task_create`

用户表达了未来要做的事、已答应的安排、需要处理的行动、要准备的事项，优先归为 `task_create`。

关键不是有没有“提醒我”“记得”“回头”这些词，而是：

```text
未来 + 用户需要行动
```

典型例子：

| 输入 | 期望分类 | 说明 |
| --- | --- | --- |
| 晚上同学约我去网吧，我同意了 | `task_create` | 未来社交安排，不是 `life_event` |
| 这两天把 PPT 做出来 | `task_create` | 明确近期工作任务 |
| 过会儿提醒我给客户发消息 | `task_create` | “过会儿”通常是短时间内 |
| 回头把会议纪要发给团队 | `task_create` | 行动明确，但时间模糊 |
| 等我到酒店后给王总回电话 | `task_create` | 条件型任务 |

保存策略：

- 明确未来行动：可自动保存。
- 行动明确但时间模糊：可自动保存，保留 `due_time_text`，不要乱填 `due_time_iso`。
- 重复任务如“每天”“偶尔”：当前可生成任务候选，但不要假装已经有完整重复提醒系统。

### `task_update`

用户不是创建新任务，而是在改变已有任务，包括完成、取消、延期、提前、改内容、改时间、改对象。

典型例子：

| 输入 | 期望分类 | 当前策略 |
| --- | --- | --- |
| 王总那个事做完了 | `task_update` | 高置信唯一匹配时可应用 |
| 明天会议取消 | `task_update` | 目标唯一时可应用，但取消后不应长期直接消失 |
| 客户沟通推到后天 | `task_update` | 目标和新时间明确时可应用 |
| 那个事终于搞定了 | `task_update` | 目标太泛，进入选择或 noMatch |

风险分级：

- `complete` 可以比 `cancel` 更积极一点，因为未识别完成通常只是重复提醒。
- `cancel` 更谨慎，因为误取消一个仍需要提醒的任务风险更高。
- `delay` 在未来提醒系统中可考虑原计划 + 新计划双提醒；当前 D0 只记录规则。
- 多候选必须让用户选择；无候选不能修改正式任务。

中期数据方向：

```text
record_status: confirmed / deleted / archived / expired ...
task_status: active / completed / cancelled ...
```

当前不要为了 D0 立刻改表，但要记录 `record_status` 和任务业务状态混用的风险。

### `short_term_state`

用户当前、今天、最近几天的临时状态。它不是任务，也不是长期画像，而是影响当前建议的上下文。

典型例子：

| 输入 | 期望分类 | 说明 |
| --- | --- | --- |
| 我今天很累 | `short_term_state` | 今日精力状态 |
| 我现在在路上，不方便接电话 | `short_term_state` | 当前场景 / 可用性 |
| 最近状态不太好 | `short_term_state` | 近期状态 |
| 今晚跑了 70 公里，累死我了 | `short_term_state` + `life_event` | 当前身体状态 + 已发生事件 |

未来子类型建议，当前可先作为 tags 或文档规则：

| 子类 | 例子 | 策略 |
| --- | --- | --- |
| `location_state` | 在路上、在办公室 | 最新状态优先，旧位置应失效 |
| `energy_state` | 累、精神好 | 保留当天变化，当前建议优先最新 |
| `mood_state` | 开心、焦虑 | 保留变化轨迹，当前建议优先最新 |
| `physical_state` | 腰酸背疼、身体不舒服 | 可保留更长短期有效期 |
| `availability_state` | 不方便电话、下午不适合重任务 | 按时间范围失效 |
| `cognitive_state` | 项目有点乱、注意力不集中 | 作为近期状态，默认 3-7 天 |

### `life_event`

已经发生的事情、一次经历、一次教训、一次以后可能有参考价值的记录。

`life_event` 不是杂物箱，而是未来理解用户的经验素材库。它未来可以用于复盘、经验总结、长期画像候选生成和重要建议，但当前不能自动升级为长期画像。

典型例子：

| 输入 | 期望分类 | 说明 |
| --- | --- | --- |
| 今天下午开了会，老板要求改方案 | `life_event` | 已发生会议和任务来源 |
| 上次运动动作不标准 | `life_event` | 已发生经验 |
| 今天客户说话让我不舒服 | `life_event` 或 `short_term_state` | 一次事件/情绪，不是长期画像 |

保存策略：

- 明确有记录价值的经验和事件可以保存。
- 不要只依赖“记一下”“记住”这两个关键词。
- 当前不自动从 `life_event` 推断长期画像。

### `profile_candidate`

长期稳定偏好、习惯、背景、价值观、工作方式。必须用户确认后才能写入正式 `profile_items`。

典型例子：

| 输入 | 期望分类 | 说明 |
| --- | --- | --- |
| 我不喜欢太频繁的提醒 | `profile_candidate` | 长期提醒偏好 |
| 我一般晚上效率高 | `profile_candidate` | 稳定工作节奏 |
| 英语对我一直很重要 | `profile_candidate` | 长期价值/目标候选 |
| 运动时我更重视动作质量，不追求极限重量 | `profile_candidate` | 长期运动原则候选 |

红线：

- 单次情绪不是长期画像。
- 单次失败或延期不是行为模式。
- 夸张表达如“我要成为歌星”要谨慎归纳，不要照字面写成长期画像。

### `general_answer`

普通问答、搜索式提问、闲聊、建议请求默认归为 `general_answer`，不生成保存卡片。

未来要区分：

| 类型 | 当前处理 | 未来方向 |
| --- | --- | --- |
| 普通知识问答 | 回答，不保存 | 可作为搜索式问答 |
| 与用户背景相关建议 | 回答，不保存 | 未来可调用用户上下文 |
| 重要人生/工作建议 | 回答，不保存 | 未来可进入深度建议页面 |
| 问答中包含任务/状态/事件 | 拆分 item | 保存可结构化部分 |

## 4. 模糊时间语义

模糊时间不能一律关键词化，也不能乱填具体日期。

| 表达 | 生活语义 | 当前 D0 处理 |
| --- | --- | --- |
| 过会儿 / 一会儿 | 短时间内，通常分钟到数小时 | 作为短期任务时间线索，保留原文 |
| 等下 / 待会儿 | 比“回头”更近 | 作为近时提醒候选，保留原文 |
| 回头 | 之后，不一定紧急 | 保存任务但保留模糊时间 |
| 有空 | 低紧急度 | 保存任务候选，不乱造时间 |
| 这两天 | 近期 | 可作为近期任务 |
| 最近 | 模糊近期 | 保留模糊时间 |
| 下次 / 以后 | 不一定是具体任务 | 结合语义判断为任务、事件或画像候选 |

提醒系统属于后续功能。D0 只定义语义，不实现提醒。

## 5. 真实例句拆分参考

### 例句 1

> 今下午开了个会，然后那个老板说让我们要去改一下方案，让我们重做个PPT，就是在这两天就得把这个PPT给做出来。

- `life_event`：今天下午开会，老板要求改方案 / 重做 PPT。
- `task_create`：这两天把 PPT 做出来。

### 例句 2

> 一周之后我要去趟山东拜访客户，然后这两天先整理客户个人信息，方便之后更好服务他。

- `task_create`：一周后去山东拜访客户。
- `task_create`：这两天整理客户资料。
- `life_event`：提前了解客户信息有助于服务客户。

### 例句 3

> 晚上可要和妹妹一起去酒吧呀，开心爽死啦！

- `task_create`：晚上和妹妹去酒吧。
- `short_term_state`：现在很开心 / 期待。

### 例句 4

> 最近别人说我唱歌难听，我要好好练唱歌了，有空的话提醒我练唱歌。

- `life_event`：最近别人说我唱歌难听。
- `task_create`：有空提醒我练唱歌。
- `profile_candidate` 候选：用户想提升唱歌能力，必须确认。

### 例句 5

> 我一直觉得身体是第一位的本钱，但很多时候懒得锻炼。每天提醒我运动。我现在感觉左右不是很平衡，提醒我练左右平衡。

- `profile_candidate`：用户重视身体健康，必须确认。
- `profile_candidate`：用户有时懒得锻炼，必须确认。
- `task_create`：每天提醒运动，当前作为重复任务候选。
- `short_term_state`：现在感觉左右不平衡。
- `task_create`：提醒练左右平衡。

### 例句 6

> 英语一直很重要，所以每天我也想锻炼一下英语口语。

- `profile_candidate`：英语对用户很重要，必须确认。
- `task_create`：每天练英语口语，当前作为重复任务候选。

### 例句 7

> 晚上跑了 70 公里，累死我了。估计明天腰酸背疼。你看用不用今晚回家提醒我拉伸一下？

- `life_event`：晚上跑了 70 公里。
- `short_term_state`：当前很累，明天可能腰酸背疼。
- `task_create`：今晚回家提醒拉伸。
- `general_answer`：用户在征求是否需要拉伸的建议，可回答但不保存为记忆。

### 例句 8

> 上次运动动作太不标准了。之后运动一定注意动作，不能追求极限重量，要追求动作品质。

- `life_event`：上次运动动作不标准。
- `profile_candidate` 候选：运动时更重视动作质量，必须确认。

### 例句 9

> 我现在在学 Vibe Coding，很多时候空闲时间刷抖音，我觉得这样不行。偶尔提醒我去学有意义的东西。

- `profile_candidate` 或 `short_term_state`：用户当前在学 Vibe Coding。
- `profile_candidate` 候选：用户希望减少无意义刷视频，必须确认。
- `task_create`：偶尔提醒学习有意义的东西，当前作为模糊重复提醒候选。

## 6. D0 执行路线

### D0-1：形成规则文档

建议新增：

```text
docs/architecture/chinese-semantic-classification-rules.md
```

内容包括：

- 总原则。
- 6 类 item 定义。
- 分类优先级。
- 自动保存策略。
- 模糊时间语义分级。
- `short_term_state` 子类型和覆盖规则。
- `task_update` 自动应用分级。
- `life_event` 的长期价值说明。
- 真实中文样例表。
- 当前版本做什么 / 暂不做什么。

### D0-2：扩展 parser sample set

修改：

```text
apps/api/src/services/parserSampleSet.ts
apps/api/test/parserSampleSet.test.ts
```

覆盖：

- 社交 / 娱乐未来安排。
- 工作客户任务。
- 模糊时间任务。
- 条件型任务。
- 任务更新。
- 当前状态变化。
- 位置状态覆盖。
- 生活事件 / 经验。
- 长期画像候选。
- 普通问答。
- 混合输入。

样例必须包含 `expectedTypes` 和必要的 `forbiddenTypes`。

### D0-3：重写 parser prompt 分类原则

修改：

```text
apps/api/src/services/parserPrompt.ts
apps/api/test/parserPrompt.test.ts
```

重点写规则，不堆关键词：

- 未来安排 / 已答应事项 / 约定 / 预约 / 要参与的活动，应优先归类为 `task_create`。
- 已发生事件、经验、教训归为 `life_event`。
- 当前 / 近期状态归为 `short_term_state`。
- 长期偏好、习惯、背景归为 `profile_candidate`，必须确认。
- 普通问答默认 `general_answer`，不保存。
- `task_update` 必须有更新动作和目标线索；泛指目标不能强行应用。

### D0-4：增强 smoke 检查

确认：

```text
apps/api/scripts/smokeParseSamples.ts
apps/api/test/smokeParseSamples.test.ts
```

持续检查：

- `expectedTypes`。
- `forbiddenTypes`。
- `profile_candidate.need_user_confirm=true`。
- `source_text` 非空。
- 模糊时间不乱造 `due_time_iso`。
- 普通问答不生成可保存记忆。

### D0-5：记录后续实现计划

当前只记录，不直接实现：

- `task_update` 完成 / 取消后的划线可见、状态标签、来源原文、撤销入口。
- 中期引入 `task_status`。
- `short_term_state` 子类型与覆盖/失效策略。
- `life_event` 作为未来自进化证据。
- 深度建议、个性化问答、提醒系统。

## 7. 验收方式

D0 文档阶段：

```bash
rg "D0|中文语义|task_create|task_update|short_term_state|life_event|profile_candidate|general_answer" \
  AGENTS.md 2026-06-05-phase3_副本.md 2026-06-07-phase3_d0_guide.md
```

D0 代码阶段：

```bash
cd apps/api
npm run typecheck
npm test
npm run smoke:parse
```

如果后续动移动端，再跑：

```bash
cd apps/mobile
flutter analyze
flutter test
```
