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
  {
    id: "tomorrow_task",
    label: "明天任务",
    text: "明天上午联系王总，确认一下项目现场的时间。",
    expectedTypes: ["task_create"],
  },
  {
    id: "today_state",
    label: "今天状态",
    text: "我今天有点累，下午可能不太适合安排太重的事情。",
    expectedTypes: ["short_term_state"],
  },
  {
    id: "long_term_preference",
    label: "长期偏好",
    text: "我不喜欢太频繁的提醒，最好只提醒真正重要的事情。",
    expectedTypes: ["profile_candidate"],
  },
  {
    id: "life_event",
    label: "生活事件",
    text: "今天做番茄炒蛋的时候糖放多了，下次要少放一点。",
    expectedTypes: ["life_event"],
  },
  {
    id: "ordinary_question",
    label: "普通问答",
    text: "番茄炒蛋怎么做会更好吃？",
    expectedTypes: ["general_answer"],
    forbiddenTypes: ["task_create", "profile_candidate"],
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
    id: "one_off_emotion",
    label: "不应保存的情绪表达",
    text: "今天客户说话让我有点不舒服，但可能只是今天这一次。",
    expectedTypes: [],
    acceptedTypes: ["short_term_state", "life_event"],
    forbiddenTypes: ["profile_candidate"],
  },
];
