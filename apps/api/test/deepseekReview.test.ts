import assert from "node:assert/strict";
import test from "node:test";

import {
  ReviewServiceError,
  createDeepSeekReview,
} from "../src/services/deepseekReview.js";
import type { ReviewRequest } from "../src/schemas/reviewResultSchema.js";

const reviewRequest: ReviewRequest = {
  timezone: "Asia/Shanghai",
  review_date: "2026-06-22",
  current_time_iso: "2026-06-22T20:00:00.000+08:00",
  user_note: "今天有点拖延。",
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

const validReviewResult = {
  title: "6月22日复盘",
  daily_summary: "今天完成了联系王总。",
  encouragement: "能把关键任务推进掉，是一个稳的进展。",
  improvement_notes: "启动稍慢，明天可以先做一个低阻力任务。",
  task_guidance: "明天优先处理有明确对象和时间的任务。",
  open_items: ["等王总反馈"],
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

test("generates a structured review through DeepSeek", async () => {
  const calls: RequestInit[] = [];
  const fetchFn = async (_url: string | URL | Request, init?: RequestInit) => {
    if (init) calls.push(init);
    return jsonCompletion(JSON.stringify(validReviewResult));
  };
  const reviewer = createDeepSeekReview({ apiKey: "test-key", fetchFn });

  const result = await reviewer(reviewRequest);

  assert.equal(result.encouragement, validReviewResult.encouragement);
  assert.equal(calls.length, 1);

  const body = JSON.parse(String(calls[0]?.body));
  assert.equal(body.response_format.type, "json_object");
  assert.equal(body.temperature, 0.55);
  assert.match(body.messages[0].content, /daily review/);
  assert.match(body.messages[1].content, /improvement_notes/);
  assert.match(body.messages[1].content, /task-1/);
});

test("returns a clear error when the review API key is missing", async () => {
  const reviewer = createDeepSeekReview({ apiKey: "" });

  await assert.rejects(
    () => reviewer(reviewRequest),
    (error) => {
      assert.equal(error instanceof ReviewServiceError, true);
      assert.equal((error as ReviewServiceError).code, "missing_api_key");
      return true;
    },
  );
});
