import assert from "node:assert/strict";
import test from "node:test";

import {
  PlanServiceError,
  createDeepSeekPlan,
} from "../src/services/deepseekPlan.js";
import type { PlanRequest } from "../src/schemas/planResultSchema.js";

const planRequest: PlanRequest = {
  timezone: "Asia/Shanghai",
  plan_date: "2026-06-23",
  current_time_iso: "2026-06-23T08:00:00.000+08:00",
  user_note: "今天上午有点累。",
  day_start_hour: 8,
  day_end_hour: 22,
  tasks: [
    {
      id: "task-1",
      title: "联系王总",
      task_status: "active",
      status: "confirmed",
    },
  ],
  short_term_states: [],
  profile_items: [],
  recent_summaries: [],
};

const validPlanResult = {
  title: "6月23日时间规划",
  overview: "上午先轻启动，下午处理联系王总。",
  blocks: [
    {
      title: "联系王总",
      block_type: "task",
      start_time_iso: "2026-06-23T15:00:00.000+08:00",
      end_time_iso: "2026-06-23T15:30:00.000+08:00",
      task_id: "task-1",
      note: "先列沟通要点。",
      reason: "这个任务有明确对象，适合安排在下午。",
      confidence: 0.8,
      source_refs: [{ source_table: "tasks", source_record_id: "task-1" }],
    },
  ],
  unscheduled_task_ids: [],
  suggestions: ["保留一点缓冲，不要把下午排满。"],
  source_refs: [{ source_table: "tasks", source_record_id: "task-1" }],
  confidence: 0.8,
};

function jsonCompletion(content: string): Response {
  return new Response(
    JSON.stringify({
      choices: [{ message: { content } }],
    }),
    { status: 200, headers: { "content-type": "application/json" } },
  );
}

test("generates a structured plan through DeepSeek", async () => {
  const calls: RequestInit[] = [];
  const fetchFn = async (_url: string | URL | Request, init?: RequestInit) => {
    if (init) calls.push(init);
    return jsonCompletion(JSON.stringify(validPlanResult));
  };
  const planner = createDeepSeekPlan({ apiKey: "test-key", fetchFn });

  const result = await planner(planRequest);

  assert.equal(result.blocks[0]?.task_id, "task-1");
  assert.equal(calls.length, 1);

  const body = JSON.parse(String(calls[0]?.body));
  assert.equal(body.response_format.type, "json_object");
  assert.equal(body.temperature, 0.45);
  assert.match(body.messages[0].content, /time planning module/);
  assert.match(body.messages[1].content, /unscheduled_task_ids/);
  assert.match(body.messages[1].content, /task-1/);
});

test("returns a clear error when the plan API key is missing", async () => {
  const planner = createDeepSeekPlan({ apiKey: "" });

  await assert.rejects(
    () => planner(planRequest),
    (error) => {
      assert.equal(error instanceof PlanServiceError, true);
      assert.equal((error as PlanServiceError).code, "missing_api_key");
      return true;
    },
  );
});
