import type { itemTypes } from "../schemas/parseResultSchema.js";

export type ParserItemType = (typeof itemTypes)[number];

export type ParserSmokeSample = {
  id: string;
  label: string;
  text: string;
  expectedTypes: ParserItemType[];
  acceptedTypes?: ParserItemType[];
  forbiddenTypes?: ParserItemType[];
};

export const parserSmokeSamples: ParserSmokeSample[] = [
  // ── task_create ──
  {
    id: "tomorrow_task",
    label: "明天任务",
    text: "明天上午联系王总，确认一下项目现场的时间。",
    expectedTypes: ["task_create"],
  },
  {
    id: "vague_time",
    label: "模糊时间",
    text: "这两天找个时间把客户资料整理一下。",
    expectedTypes: ["task_create"],
  },
  {
    id: "multiple_tasks",
    label: "多个任务混合",
    text: "明天联系王总，后天把会议纪要发给团队，再提醒我周五看预算表。",
    expectedTypes: ["task_create"],
  },
  {
    id: "business_trip_scenario",
    label: "出差场景",
    text: "下周一去上海出差，周二拜访客户，记得带上合同和方案。",
    expectedTypes: ["task_create"],
  },
  {
    id: "client_project_scenario",
    label: "客户项目场景",
    text: "给客户张总发项目周报，附件里要有上周的进度对比。",
    expectedTypes: ["task_create"],
  },
  {
    id: "task_vague_deadline",
    label: "任务模糊截止时间",
    text: "反正最近有空的时候整理一下那个合同。",
    expectedTypes: ["task_create"],
  },

  // ── task_update ──
  {
    id: "task_update_complete",
    label: "任务更新：完成",
    text: "联系王总这件事已经做完了。",
    expectedTypes: ["task_update"],
  },
  {
    id: "task_update_cancel",
    label: "任务更新：取消",
    text: "取消掉明天那个会议，不想开了。",
    expectedTypes: ["task_update"],
  },
  {
    id: "task_update_delay",
    label: "任务更新：延期",
    text: "把整理客户资料这件事往后推三天。",
    expectedTypes: ["task_update"],
  },
  {
    id: "task_update_edit",
    label: "任务更新：修改",
    text: "把联系王总改成联系张总。",
    expectedTypes: ["task_update"],
  },
  {
    id: "task_update_multi_candidate",
    label: "任务更新：多候选",
    text: "联系王总这件事往后挪一挪。",
    expectedTypes: ["task_update"],
  },
  {
    id: "task_update_no_target",
    label: "任务更新：无明确目标",
    text: "那个事终于搞定了。",
    expectedTypes: ["task_update"],
  },

  // ── short_term_state ──
  {
    id: "today_state",
    label: "今天状态",
    text: "我今天有点累，下午可能不太适合安排太重的事情。",
    expectedTypes: ["short_term_state"],
  },
  {
    id: "short_term_energy",
    label: "短期精力状态",
    text: "这两天睡眠不太好，白天精神不太集中。",
    expectedTypes: ["short_term_state"],
  },
  {
    id: "short_term_mood",
    label: "短期情绪状态",
    text: "最近心情还不错，感觉工作节奏慢慢调整过来了。",
    expectedTypes: ["short_term_state"],
  },
  {
    id: "short_term_on_the_road",
    label: "短期出行状态",
    text: "我现在在路上，不方便接电话，大概一个小时后到公司。",
    expectedTypes: ["short_term_state"],
  },
  {
    id: "one_off_emotion",
    label: "一次性情绪，不应变长期画像",
    text: "今天客户说话让我有点不舒服，但可能只是今天这一次。",
    expectedTypes: [],
    acceptedTypes: ["short_term_state", "life_event"],
    forbiddenTypes: ["profile_candidate"],
  },
  {
    id: "one_off_frustration",
    label: "一次性挫折情绪",
    text: "今天客户提了个很无理的需求，有点生气。",
    expectedTypes: [],
    acceptedTypes: ["short_term_state", "life_event"],
    forbiddenTypes: ["profile_candidate"],
  },

  // ── life_event ──
  {
    id: "life_event_cooking",
    label: "生活事件：做菜经验",
    text: "今天做番茄炒蛋的时候糖放多了，下次要少放一点。",
    expectedTypes: ["life_event"],
  },
  {
    id: "life_event_cooking_tip",
    label: "生活事件：做菜心得",
    text: "今天做菜的时候发现先放盐再放糖味道更好。",
    expectedTypes: ["life_event"],
  },
  {
    id: "life_event_travel_lesson",
    label: "生活事件：出差教训",
    text: "这次出差忘了提前订酒店，到了才找很被动，下次要记住。",
    expectedTypes: ["life_event"],
  },

  // ── general_answer ──
  {
    id: "ordinary_question",
    label: "普通问答",
    text: "番茄炒蛋怎么做会更好吃？",
    expectedTypes: ["general_answer"],
    forbiddenTypes: ["task_create", "profile_candidate"],
  },
  {
    id: "chitchat_weather",
    label: "闲聊天气（可能无记忆价值）",
    text: "今天天气真好啊，适合出去走走。",
    expectedTypes: [],
    acceptedTypes: ["general_answer"],
    forbiddenTypes: ["task_create", "profile_candidate"],
  },
  {
    id: "chitchat_life_advice",
    label: "闲聊人生建议",
    text: "你觉得我应该换工作吗？",
    expectedTypes: ["general_answer"],
    forbiddenTypes: ["task_create", "profile_candidate"],
  },
  {
    id: "general_cooking_question",
    label: "一般烹饪问答",
    text: "番茄鸡蛋先放哪个比较好？",
    expectedTypes: ["general_answer"],
    forbiddenTypes: ["task_create", "profile_candidate"],
  },

  // ── profile_candidate ──
  {
    id: "long_term_preference",
    label: "长期偏好：提醒频率",
    text: "我不喜欢太频繁的提醒，最好只提醒真正重要的事情。",
    expectedTypes: ["profile_candidate"],
  },
  {
    id: "profile_evening_efficiency",
    label: "长期画像：晚上效率高",
    text: "我一般晚上效率比较高，不太适合一早就安排重要会议。",
    expectedTypes: ["profile_candidate"],
  },
  {
    id: "profile_direct_communication",
    label: "长期画像：直接沟通偏好",
    text: "我希望别人跟我说话直接一点，不用绕弯子。",
    expectedTypes: ["profile_candidate"],
  },
  {
    id: "profile_frequent_travel",
    label: "长期画像：经常出差",
    text: "我经常出差，大概一个月有一半时间在外面。",
    expectedTypes: ["profile_candidate"],
  },
  {
    id: "profile_avoid_morning_push",
    label: "长期画像：避免早上催促",
    text: "我不太喜欢在早上被催促，更适合下午集中处理重要事情。",
    expectedTypes: ["profile_candidate"],
  },

  // ── 多意图 ──
  {
    id: "multi_intent_task_state_profile",
    label: "多意图：任务、短期状态、长期画像",
    text: "明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。",
    expectedTypes: ["task_create", "short_term_state", "profile_candidate"],
  },
  {
    id: "multi_intent_state_event",
    label: "多意图：短期状态和生活事件",
    text: "今天客户沟通不太顺利，记录一下，我现在有点累。",
    expectedTypes: ["short_term_state", "life_event"],
  },

  // ── 边界样例 ──
  {
    id: "edge_recent_procrastination",
    label: "近期拖延不应是长期画像",
    text: "最近有点拖延，好几件事都推了好几天。",
    expectedTypes: [],
    acceptedTypes: ["short_term_state"],
    forbiddenTypes: ["profile_candidate"],
  },
  {
    id: "edge_temporary_confusion",
    label: "暂时困惑不应生成画像",
    text: "最近手上的项目有点乱，不知道先做哪个好。",
    expectedTypes: [],
    acceptedTypes: ["short_term_state"],
    forbiddenTypes: ["profile_candidate"],
  },
];
