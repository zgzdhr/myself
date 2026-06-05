import assert from "node:assert/strict";
import test from "node:test";

import { itemTypes } from "../src/schemas/parseResultSchema.js";
import { parserSmokeSamples } from "../src/services/parserSampleSet.js";

const validTypes = new Set<string>(itemTypes);

// ── 结构和数量 ──

test("sample count is at least 30", () => {
  assert.ok(parserSmokeSamples.length >= 30);
});

test("sample IDs are unique", () => {
  const ids = parserSmokeSamples.map((s) => s.id);
  assert.equal(new Set(ids).size, ids.length);
});

test("every sample has id, label, and non-trivial text", () => {
  for (const sample of parserSmokeSamples) {
    assert.ok(sample.id);
    assert.ok(sample.label);
    assert.ok(sample.text.length >= 4);

    assert.ok(
      sample.expectedTypes.length >= 1 ||
        (sample.acceptedTypes?.length ?? 0) >= 1,
    );

    for (const type of sample.expectedTypes) {
      assert.equal(validTypes.has(type), true, `unknown type ${type} in ${sample.id}`);
    }
    for (const type of sample.acceptedTypes ?? []) {
      assert.equal(validTypes.has(type), true, `unknown accepted type ${type} in ${sample.id}`);
    }
    for (const type of sample.forbiddenTypes ?? []) {
      assert.equal(validTypes.has(type), true, `unknown forbidden type ${type} in ${sample.id}`);
    }
  }
});

// ── 类型覆盖 ──

test("each core item type appears in at least 2 samples (expected or accepted)", () => {
  for (const type of itemTypes) {
    const count = parserSmokeSamples.filter(
      (s) =>
        s.expectedTypes.includes(type) ||
        (s.acceptedTypes ?? []).includes(type),
    ).length;
    assert.ok(count >= 2, `${type} appears in ${count} samples, need at least 2`);
  }
});

// ── task_update 语义覆盖 ──

test("task_update samples cover complete / cancel / delay / edit semantics", () => {
  const taskUpdateSamples = parserSmokeSamples.filter((s) =>
    s.expectedTypes.includes("task_update"),
  );
  assert.ok(taskUpdateSamples.length >= 4);

  const texts = taskUpdateSamples.map((s) => s.text).join("\n");

  // complete
  assert.ok(/做完|完成|搞定|已经/.test(texts), "missing complete semantics");
  // cancel
  assert.ok(/取消|不开了|算了/.test(texts), "missing cancel semantics");
  // delay
  assert.ok(/往后|延期|推迟|推后/.test(texts), "missing delay semantics");
  // edit
  assert.ok(/改|换成|变成/.test(texts), "missing edit semantics");
});

// ── 关键规则 ──

test("one-off emotion samples are explicitly not profile candidates", () => {
  for (const sample of parserSmokeSamples) {
    if (
      sample.id === "one_off_emotion" ||
      sample.id === "one_off_frustration"
    ) {
      assert.deepEqual(sample.expectedTypes, []);
      assert.equal(
        sample.forbiddenTypes?.includes("profile_candidate"),
        true,
        `${sample.id} must forbid profile_candidate`,
      );
    }
  }
});

test("ordinary question / chitchat samples forbid task and profile", () => {
  const qaIds = [
    "ordinary_question",
    "chitchat_weather",
    "chitchat_life_advice",
    "general_cooking_question",
  ];
  for (const id of qaIds) {
    const sample = parserSmokeSamples.find((s) => s.id === id);
    assert.ok(sample, `${id} sample missing`);
    const hasGeneralAnswer =
      sample.expectedTypes.includes("general_answer") ||
      (sample.acceptedTypes ?? []).includes("general_answer");
    assert.ok(hasGeneralAnswer, `${id} should accept general_answer`);
    assert.ok(sample.forbiddenTypes?.includes("task_create"));
    assert.ok(sample.forbiddenTypes?.includes("profile_candidate"));
  }
});

test("edge procrastination / confusion samples forbid profile_candidate", () => {
  for (const id of ["edge_recent_procrastination", "edge_temporary_confusion"]) {
    const sample = parserSmokeSamples.find((s) => s.id === id);
    assert.ok(sample, `${id} not found`);
    assert.deepEqual(sample.expectedTypes, []);
    assert.equal(
      sample.forbiddenTypes?.includes("profile_candidate"),
      true,
      `${id} must forbid profile_candidate`,
    );
  }
});

test("profile_candidate samples appear in the set", () => {
  const profileSamples = parserSmokeSamples.filter((s) =>
    s.expectedTypes.includes("profile_candidate"),
  );
  assert.ok(profileSamples.length >= 2);
});
