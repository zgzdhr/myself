import assert from "node:assert/strict";
import test from "node:test";

import {
  reviewRequestSchema,
  reviewResultSchema,
} from "../src/schemas/reviewResultSchema.js";

test("accepts a bounded daily review request", () => {
  const result = reviewRequestSchema.safeParse({
    timezone: "Asia/Shanghai",
    review_date: "2026-06-22",
    current_time_iso: "2026-06-22T20:00:00.000+08:00",
    user_note: "今天有点拖延，但下午处理完了一个重要任务。",
    tasks: [
      {
        id: "task-1",
        title: "联系王总",
        due_time_iso: "2026-06-22T15:00:00.000+08:00",
        task_status: "completed",
        status: "confirmed",
      },
    ],
    short_term_states: [
      {
        id: "state-1",
        content: "今天有点累",
        status: "confirmed",
      },
    ],
    life_events: [],
    profile_items: [],
  });

  assert.equal(result.success, true);
});

test("requires review output to include encouragement and improvement notes", () => {
  const result = reviewResultSchema.safeParse({
    title: "6月22日复盘",
    daily_summary: "今天完成了联系王总，也记录到下午状态有所恢复。",
    encouragement: "你没有因为上午状态差就放弃，这一点值得肯定。",
    improvement_notes: "上午启动偏慢，明天可以先安排一个低阻力任务。",
    task_guidance: "明天先处理有明确截止时间的任务，再处理开放事项。",
    open_items: ["确认王总后续反馈"],
    source_refs: [{ source_table: "tasks", source_record_id: "task-1" }],
    confidence: 0.82,
  });

  assert.equal(result.success, true);
});
