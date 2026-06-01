import assert from "node:assert/strict";
import test from "node:test";

import { itemTypes } from "../src/schemas/parseResultSchema.js";
import { parserSmokeSamples } from "../src/services/parserSampleSet.js";

const validTypes = new Set<string>(itemTypes);

test("parser smoke sample set covers the eight Phase 2 scenarios", () => {
  assert.equal(parserSmokeSamples.length, 8);
  assert.equal(new Set(parserSmokeSamples.map((sample) => sample.id)).size, 8);

  for (const sample of parserSmokeSamples) {
    assert.ok(sample.id);
    assert.ok(sample.label);
    assert.ok(sample.text.length >= 4);
    assert.ok(
      sample.expectedTypes.length >= 1 || (sample.acceptedTypes?.length ?? 0) >= 1,
    );

    for (const type of sample.expectedTypes) {
      assert.equal(validTypes.has(type), true);
    }

    for (const type of sample.acceptedTypes ?? []) {
      assert.equal(validTypes.has(type), true);
    }

    for (const type of sample.forbiddenTypes ?? []) {
      assert.equal(validTypes.has(type), true);
    }
  }
});

test("one-off emotion sample is explicitly not a profile candidate", () => {
  const sample = parserSmokeSamples.find(
    (candidate) => candidate.id === "one_off_emotion",
  );

  assert.ok(sample);
  assert.deepEqual(sample.expectedTypes, []);
  assert.deepEqual(sample.acceptedTypes, ["short_term_state", "life_event"]);
  assert.deepEqual(sample.forbiddenTypes, ["profile_candidate"]);
});

test("ordinary question sample is classified as general answer only", () => {
  const sample = parserSmokeSamples.find(
    (candidate) => candidate.id === "ordinary_question",
  );

  assert.ok(sample);
  assert.deepEqual(sample.expectedTypes, ["general_answer"]);
  assert.equal(sample.forbiddenTypes?.includes("profile_candidate"), true);
});
