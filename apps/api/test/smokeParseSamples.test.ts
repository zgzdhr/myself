import assert from "node:assert/strict";
import test from "node:test";

import { evaluateSampleResult, runParseSmoke } from "../scripts/smokeParseSamples.js";
import type { ParseResult } from "../src/schemas/parseResultSchema.js";
import type { ParserSmokeSample } from "../src/services/parserSampleSet.js";

const sample: ParserSmokeSample = {
  id: "sample",
  label: "sample",
  text: "明天联系王总",
  expectedTypes: ["task_create"],
  forbiddenTypes: ["profile_candidate"],
};

const validResult: ParseResult = {
  user_reply: "我帮你整理出了一个任务。",
  input_summary: "明天联系王总。",
  intent_types: ["task_create"],
  items: [
    {
      type: "task_create",
      title: "联系王总",
      source_text: "明天联系王总",
      tags: ["work"],
      confidence: 0.9,
      need_user_confirm: true,
    },
  ],
  memory_candidates: [],
  safety_flags: [],
  need_follow_up_question: false,
  follow_up_question: null,
};

test("evaluates parser smoke result against expected and forbidden types", () => {
  assert.deepEqual(evaluateSampleResult(sample, validResult), {
    sampleId: "sample",
    label: "sample",
    ok: true,
    actualTypes: ["task_create"],
    missingTypes: [],
    forbiddenTypes: [],
  });

  assert.equal(
    evaluateSampleResult(
      sample,
      {
        ...validResult,
        intent_types: ["profile_candidate"],
        items: [
          {
            type: "profile_candidate",
            content: "用户不喜欢太频繁的提醒",
            source_text: "我不喜欢太频繁的提醒",
            tags: ["preference"],
            confidence: 0.9,
            need_user_confirm: true,
          },
        ],
      },
    ).ok,
    false,
  );
});

test("allows accepted alternative types for ambiguous boundary samples", () => {
  assert.equal(
    evaluateSampleResult(
      {
        id: "ambiguous",
        label: "ambiguous",
        text: "今天客户说话让我有点不舒服",
        expectedTypes: [],
        acceptedTypes: ["short_term_state", "life_event"],
        forbiddenTypes: ["profile_candidate"],
      },
      {
        ...validResult,
        intent_types: ["short_term_state"],
        items: [
          {
            type: "short_term_state",
            content: "用户今天有点不舒服",
            source_text: "今天客户说话让我有点不舒服",
            tags: ["emotion"],
            confidence: 0.8,
            need_user_confirm: false,
          },
        ],
      },
    ).ok,
    true,
  );
});

test("runParseSmoke checks health and posts every sample to parse endpoint", async () => {
  const requestedUrls: string[] = [];
  const requestedBodies: unknown[] = [];

  const results = await runParseSmoke({
    baseUrl: "http://127.0.0.1:8787",
    samples: [sample],
    fetchFn: async (input, init) => {
      requestedUrls.push(String(input));
      if (init?.body) {
        requestedBodies.push(JSON.parse(String(init.body)));
      }

      if (String(input).endsWith("/health")) {
        return Response.json({ ok: true });
      }

      return Response.json(validResult);
    },
  });

  assert.deepEqual(requestedUrls, [
    "http://127.0.0.1:8787/health",
    "http://127.0.0.1:8787/parse",
  ]);
  assert.deepEqual(requestedBodies, [
    { text: "明天联系王总", timezone: "Asia/Shanghai" },
  ]);
  assert.equal(results[0]?.ok, true);
});
