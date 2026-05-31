import assert from "node:assert/strict";
import test from "node:test";

import { parseResultSchema } from "../src/schemas/parseResultSchema.js";

const validParseResult = {
  user_reply: "我帮你整理出了 1 个任务、1 条短期状态和 1 条长期画像候选。",
  input_summary: "明天上午联系王总，我今天很累，我不喜欢太频繁的提醒。",
  intent_types: ["task_create", "short_term_state", "profile_candidate"],
  items: [
    {
      type: "task_create",
      title: "联系王总",
      source_text: "明天上午联系王总",
      tags: ["work", "customer"],
      confidence: 0.9,
      need_user_confirm: true,
    },
    {
      type: "short_term_state",
      content: "用户今天感觉疲惫",
      source_text: "我今天很累",
      tags: ["energy"],
      confidence: 0.8,
      need_user_confirm: false,
      valid_days: 1,
    },
    {
      type: "profile_candidate",
      content: "用户不喜欢太频繁的提醒",
      source_text: "我不喜欢太频繁的提醒",
      tags: ["preference", "reminder"],
      confidence: 0.86,
      need_user_confirm: true,
    },
  ],
};

const taskItem = validParseResult.items[0] as Record<string, unknown>;

test("accepts a valid task, state, and profile parse result", () => {
  const result = parseResultSchema.safeParse(validParseResult);

  assert.equal(result.success, true);
  if (result.success) {
    assert.deepEqual(result.data.intent_types, [
      "task_create",
      "short_term_state",
      "profile_candidate",
    ]);
    assert.equal(result.data.items.length, 3);
  }
});

test("rejects unknown item types", () => {
  const result = parseResultSchema.safeParse({
    ...validParseResult,
    items: [{ ...taskItem, type: "calendar_event" }],
  });

  assert.equal(result.success, false);
});

test("rejects items missing source_text", () => {
  const { source_text: _sourceText, ...itemWithoutSource } = taskItem;

  const result = parseResultSchema.safeParse({
    ...validParseResult,
    items: [itemWithoutSource],
  });

  assert.equal(result.success, false);
});

test("rejects confidence values outside 0 to 1", () => {
  const result = parseResultSchema.safeParse({
    ...validParseResult,
    items: [{ ...taskItem, confidence: 1.5 }],
  });

  assert.equal(result.success, false);
});

test("rejects profile candidates that do not require user confirmation", () => {
  const result = parseResultSchema.safeParse({
    ...validParseResult,
    items: [
      {
        ...validParseResult.items[2],
        need_user_confirm: false,
      },
    ],
  });

  assert.equal(result.success, false);
});
