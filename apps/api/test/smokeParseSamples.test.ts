import assert from "node:assert/strict";
import test from "node:test";

import {
  evaluateSampleResult,
  runParseSmoke,
} from "../scripts/smokeParseSamples.js";
import type { ParseResult } from "../src/schemas/parseResultSchema.js";
import type { ParserSmokeSample } from "../src/services/parserSampleSet.js";

// ── helpers ──

function sample(overrides: Partial<ParserSmokeSample> = {}): ParserSmokeSample {
  return {
    id: "sample",
    label: "sample",
    text: "明天联系王总",
    expectedTypes: ["task_create"],
    ...overrides,
  };
}

function result(overrides: Partial<ParseResult> = {}): ParseResult {
  return {
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
    ...overrides,
  };
}

function profileCandidateItem(overrides: Record<string, unknown> = {}) {
  return {
    type: "profile_candidate" as const,
    content: "用户偏好",
    source_text: "原文片段",
    tags: ["preference"],
    confidence: 0.9,
    need_user_confirm: true,
    ...overrides,
  };
}

// ── type checks (existing) ──

test("evaluates parser smoke result against expected and forbidden types", () => {
  const res = evaluateSampleResult(
    sample({ expectedTypes: ["task_create"], forbiddenTypes: ["profile_candidate"] }),
    result(),
  );
  assert.deepEqual(res, {
    sampleId: "sample",
    label: "sample",
    ok: true,
    actualTypes: ["task_create"],
    missingTypes: [],
    forbiddenTypes: [],
    ruleFailures: [],
  });

  const failRes = evaluateSampleResult(
    sample({ expectedTypes: ["task_create"], forbiddenTypes: ["profile_candidate"] }),
    result({
      intent_types: ["profile_candidate"],
      items: [profileCandidateItem()],
    }),
  );
  assert.equal(failRes.ok, false);
  assert.deepEqual(failRes.missingTypes, ["task_create"]);
});

test("allows accepted alternative types for ambiguous boundary samples", () => {
  const res = evaluateSampleResult(
    sample({
      id: "ambiguous",
      label: "ambiguous",
      text: "今天客户让我不舒服",
      expectedTypes: [],
      acceptedTypes: ["short_term_state", "life_event"],
      forbiddenTypes: ["profile_candidate"],
    }),
    result({
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
    }),
  );
  assert.equal(res.ok, true);
});

test("missing expected type causes failure", () => {
  const res = evaluateSampleResult(
    sample({ expectedTypes: ["task_create", "short_term_state"] }),
    result(), // only has task_create
  );
  assert.equal(res.ok, false);
  assert.deepEqual(res.missingTypes, ["short_term_state"]);
});

test("forbidden type appearing causes failure", () => {
  const res = evaluateSampleResult(
    sample({ expectedTypes: ["general_answer"], forbiddenTypes: ["profile_candidate"] }),
    result({
      intent_types: ["profile_candidate"],
      items: [profileCandidateItem()],
    }),
  );
  assert.equal(res.ok, false);
  assert.deepEqual(res.forbiddenTypes, ["profile_candidate"]);
});

// ── rule checks (new) ──

test("profile_candidate with need_user_confirm=false causes rule failure", () => {
  const res = evaluateSampleResult(
    sample({ expectedTypes: ["profile_candidate"] }),
    result({
      intent_types: ["profile_candidate"],
      items: [profileCandidateItem({ need_user_confirm: false })],
    }),
  );
  assert.equal(res.ok, false);
  assert.equal(res.ruleFailures.length, 1);
  assert.match(res.ruleFailures[0]!, /need_user_confirm/);
});

test("empty source_text causes rule failure", () => {
  const res = evaluateSampleResult(
    sample(),
    result({
      items: [
        {
          type: "task_create",
          title: "无来源文本",
          source_text: "",
          tags: [],
          confidence: 0.8,
          need_user_confirm: true,
        },
      ],
    }),
  );
  assert.equal(res.ok, false);
  assert.equal(res.ruleFailures.length, 1);
  assert.match(res.ruleFailures[0]!, /source_text/);
});

test("confidence out of bounds causes rule failure", () => {
  const res = evaluateSampleResult(
    sample(),
    result({
      items: [
        {
          type: "task_create",
          title: "异常置信度",
          source_text: "测试",
          tags: [],
          confidence: 1.5,
          need_user_confirm: true,
        },
      ],
    }),
  );
  assert.equal(res.ok, false);
  assert.equal(res.ruleFailures.length, 1);
  assert.match(res.ruleFailures[0]!, /confidence/);
});

test("confidence=0 and confidence=1 are valid", () => {
  let res = evaluateSampleResult(
    sample(),
    result({
      items: [
        {
          type: "task_create",
          title: "零置信度",
          source_text: "测试",
          tags: [],
          confidence: 0,
          need_user_confirm: true,
        },
      ],
    }),
  );
  assert.equal(res.ok, true);

  res = evaluateSampleResult(
    sample(),
    result({
      items: [
        {
          type: "task_create",
          title: "满置信度",
          source_text: "测试",
          tags: [],
          confidence: 1,
          need_user_confirm: true,
        },
      ],
    }),
  );
  assert.equal(res.ok, true);
});

test("vague time with fabricated ISO causes rule failure", () => {
  const res = evaluateSampleResult(
    sample({
      id: "vague_time_task",
      label: "模糊时间任务",
      text: "最近有空整理合同",
      expectedTypes: ["task_create"],
    }),
    result({
      items: [
        {
          type: "task_create",
          title: "整理合同",
          source_text: "最近有空整理合同",
          tags: ["work"],
          confidence: 0.7,
          need_user_confirm: true,
          due_time_text: "最近有空",
          due_time_iso: "2026-06-08T00:00:00Z",
        },
      ],
    }),
  );
  assert.equal(res.ok, false);
  assert.equal(res.ruleFailures.length, 1);
  assert.match(res.ruleFailures[0]!, /due_time_iso/);
});

test("vague time without ISO is acceptable", () => {
  const res = evaluateSampleResult(
    sample({
      id: "vague_time_task",
      label: "模糊时间任务",
      text: "最近有空整理合同",
      expectedTypes: ["task_create"],
    }),
    result({
      items: [
        {
          type: "task_create",
          title: "整理合同",
          source_text: "最近有空整理合同",
          tags: ["work"],
          confidence: 0.7,
          need_user_confirm: true,
          due_time_text: "最近有空",
        },
      ],
    }),
  );
  assert.equal(res.ok, true);
});

test("D0 vague time phrases reject fabricated ISO dates", () => {
  const vaguePhrases = ["过会儿", "一会儿", "待会儿", "回头", "有空", "等我到酒店后"];

  for (const phrase of vaguePhrases) {
    const res = evaluateSampleResult(
      sample({
        id: `vague_time_${phrase}`,
        label: `模糊时间：${phrase}`,
        text: `${phrase}提醒我给客户发消息`,
        expectedTypes: ["task_create"],
      }),
      result({
        items: [
          {
            type: "task_create",
            title: "给客户发消息",
            source_text: `${phrase}提醒我给客户发消息`,
            tags: ["work"],
            confidence: 0.8,
            need_user_confirm: true,
            due_time_text: phrase,
            due_time_iso: "2026-06-08T00:00:00Z",
          },
        ],
      }),
    );
    assert.equal(res.ok, false, `${phrase} should not allow fabricated ISO`);
    assert.ok(
      res.ruleFailures.some((failure) => failure.includes("due_time_iso")),
      `${phrase} should report a due_time_iso rule failure`,
    );
  }
});

test("general_answer sample producing saveable items causes rule failure", () => {
  const res = evaluateSampleResult(
    sample({
      id: "chitchat",
      label: "闲聊",
      text: "今天天气真好",
      expectedTypes: ["general_answer"],
      forbiddenTypes: ["task_create", "profile_candidate"],
    }),
    result({
      intent_types: ["task_create"],
      items: [
        {
          type: "task_create",
          title: "散步",
          source_text: "出去走走",
          tags: [],
          confidence: 0.6,
          need_user_confirm: true,
        },
      ],
    }),
  );
  assert.equal(res.ok, false);
  // forbiddenTypes already catches this, and the rule adds extra detail
  assert.ok(
    res.forbiddenTypes.includes("task_create") ||
      res.ruleFailures.some((f) => f.includes("saveable")),
  );
});

// ── schema error / HTTP error handling ──

test("runParseSmoke catches per-sample HTTP errors without aborting", async () => {
  let callCount = 0;
  const results = await runParseSmoke({
    baseUrl: "http://127.0.0.1:9999",
    samples: [
      sample({ id: "bad", label: "bad" }),
      sample({ id: "ok", label: "ok" }),
    ],
    fetchFn: async (input) => {
      callCount++;
      if (callCount === 1) return { ok: true } as Response; // health
      if (callCount === 2) throw new Error("connect ECONNREFUSED");
      return Response.json(result());
    },
  });

  assert.equal(results.length, 2);
  assert.equal(results[0]!.ok, false);
  assert.match(results[0]!.ruleFailures[0]!, /HTTP request failed/);
  assert.equal(results[1]!.ok, true);
});

test("runParseSmoke catches schema errors per-sample", async () => {
  let callCount = 0;
  const results = await runParseSmoke({
    baseUrl: "http://127.0.0.1:9999",
    samples: [sample({ id: "bad_schema", label: "bad schema" })],
    fetchFn: async (input) => {
      callCount++;
      if (callCount === 1) return { ok: true } as Response;
      return Response.json({ invalid: true });
    },
  });

  assert.equal(results.length, 1);
  assert.equal(results[0]!.ok, false);
  assert.match(results[0]!.ruleFailures[0]!, /schema error/);
});

test("runParseSmoke handles non-JSON responses", async () => {
  let callCount = 0;
  const results = await runParseSmoke({
    baseUrl: "http://127.0.0.1:9999",
    samples: [sample({ id: "not_json", label: "not json" })],
    fetchFn: async (input) => {
      callCount++;
      if (callCount === 1) return { ok: true } as Response;
      return { ok: true, json: async () => { throw new Error("invalid json"); } } as unknown as Response;
    },
  });

  assert.equal(results[0]!.ok, false);
  assert.match(results[0]!.ruleFailures[0]!, /not valid JSON/);
});
