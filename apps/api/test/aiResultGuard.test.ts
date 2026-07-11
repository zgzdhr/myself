import assert from "node:assert/strict";
import test from "node:test";

import {
  validatePlanResultForRequest,
  validateReviewResultForRequest,
} from "../src/services/aiResultGuard.js";
import type { PlanRequest, PlanResult } from "../src/schemas/planResultSchema.js";
import type {
  ReviewRequest,
  ReviewResult,
} from "../src/schemas/reviewResultSchema.js";

const reviewRequest: ReviewRequest = {
  timezone: "Asia/Shanghai",
  review_date: "2026-07-11",
  current_time_iso: "2026-07-11T20:00:00+08:00",
  user_note: "",
  tasks: [
    {
      id: "task-1",
      title: "联系王总",
      task_status: "completed",
      status: "confirmed",
    },
  ],
  short_term_states: [],
  life_events: [],
  profile_items: [],
};

const reviewResult: ReviewResult = {
  title: "今日复盘",
  daily_summary: "完成了联系王总。",
  encouragement: "你推进了关键沟通。",
  improvement_notes: "明天先安排一个小启动任务。",
  task_guidance: "继续跟进后续反馈。",
  open_items: [],
  source_refs: [{ source_table: "tasks", source_record_id: "task-1" }],
  confidence: 0.8,
  uncertainty_notes: [],
};

const planRequest: PlanRequest = {
  timezone: "Asia/Shanghai",
  plan_date: "2026-07-11",
  current_time_iso: "2026-07-11T08:00:00+08:00",
  user_note: "",
  day_start_hour: 8,
  day_end_hour: 22,
  tasks: [
    {
      id: "task-active",
      title: "写方案",
      task_status: "active",
      status: "confirmed",
    },
    {
      id: "task-completed",
      title: "已完成任务",
      task_status: "completed",
      status: "confirmed",
    },
  ],
  short_term_states: [],
  profile_items: [],
  recent_summaries: [],
};

const planResult: PlanResult = {
  title: "今日计划",
  overview: "上午启动，下午处理方案。",
  blocks: [
    {
      title: "写方案",
      block_type: "task",
      start_time_iso: "2026-07-11T09:00:00+08:00",
      end_time_iso: "2026-07-11T10:00:00+08:00",
      task_id: "task-active",
      note: "先列提纲。",
      reason: "这是当前活跃任务。",
      confidence: 0.8,
      source_refs: [
        { source_table: "tasks", source_record_id: "task-active" },
      ],
    },
  ],
  unscheduled_task_ids: [],
  suggestions: [],
  source_refs: [
    { source_table: "tasks", source_record_id: "task-active" },
  ],
  confidence: 0.8,
  uncertainty_notes: [],
};

test("review guard rejects fabricated source references", () => {
  const result = validateReviewResultForRequest(reviewRequest, {
    ...reviewResult,
    source_refs: [{ source_table: "tasks", source_record_id: "task-other" }],
  });

  assert.equal(result.ok, false);
});

test("plan guard accepts bounded blocks grounded in active input tasks", () => {
  assert.deepEqual(validatePlanResultForRequest(planRequest, planResult), {
    ok: true,
  });
});

test("plan guard rejects invented ids, completed tasks, and out-of-window time", () => {
  const result = validatePlanResultForRequest(planRequest, {
    ...planResult,
    blocks: [
      {
        ...planResult.blocks[0]!,
        start_time_iso: "2026-07-12T07:00:00+08:00",
        end_time_iso: "2026-07-12T08:00:00+08:00",
        task_id: "task-completed",
        source_refs: [
          { source_table: "tasks", source_record_id: "fabricated" },
        ],
      },
    ],
    unscheduled_task_ids: ["missing-task"],
  });

  assert.equal(result.ok, false);
  if (!result.ok) {
    assert.ok(result.issues.length >= 3);
  }
});
