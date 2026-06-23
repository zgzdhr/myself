import assert from "node:assert/strict";
import test from "node:test";

import {
  planRequestSchema,
  planResultSchema,
} from "../src/schemas/planResultSchema.js";

test("accepts a bounded daily plan request", () => {
  const result = planRequestSchema.safeParse({
    timezone: "Asia/Shanghai",
    plan_date: "2026-06-23",
    current_time_iso: "2026-06-23T08:00:00.000+08:00",
    user_note: "今天上午精神一般，下午适合做重点任务。",
    day_start_hour: 8,
    day_end_hour: 22,
    tasks: [
      {
        id: "task-1",
        title: "联系王总",
        due_time_iso: "2026-06-23T15:00:00.000+08:00",
        task_status: "active",
        status: "confirmed",
      },
    ],
    short_term_states: [
      {
        id: "state-1",
        content: "今天上午有点累",
        status: "confirmed",
      },
    ],
    profile_items: [],
    recent_summaries: [],
  });

  assert.equal(result.success, true);
});

test("requires plan blocks to have a valid time range", () => {
  const result = planResultSchema.safeParse({
    title: "6月23日时间规划",
    overview: "今天先用轻任务启动，下午处理联系王总。",
    blocks: [
      {
        title: "联系王总",
        block_type: "task",
        start_time_iso: "2026-06-23T15:00:00.000+08:00",
        end_time_iso: "2026-06-23T15:30:00.000+08:00",
        task_id: "task-1",
        note: "先确认沟通重点。",
        reason: "任务有明确对象和截止时间，适合放在下午状态较稳时处理。",
        confidence: 0.82,
        source_refs: [{ source_table: "tasks", source_record_id: "task-1" }],
      },
    ],
    unscheduled_task_ids: [],
    suggestions: ["如果上午状态差，可以把启动任务缩短到 15 分钟。"],
    source_refs: [{ source_table: "tasks", source_record_id: "task-1" }],
    confidence: 0.8,
  });

  assert.equal(result.success, true);
});
