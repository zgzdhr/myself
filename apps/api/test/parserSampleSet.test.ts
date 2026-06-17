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

test("D0 semantic calibration samples cover real Chinese lifestyle boundaries", () => {
  const requiredSampleIds = [
    "d0_social_entertainment_future_agreement",
    "d0_social_bar_plan_with_mood",
    "d0_remember_past_book_is_not_task",
    "d0_short_vague_customer_reminder",
    "d0_callback_after_hotel_condition",
    "d0_meeting_ppt_work_multi_intent",
    "d0_shandong_customer_visit_preparation",
    "d0_recurring_english_speaking_goal",
    "d0_exercise_quality_lesson",
    "d0_vibe_coding_distraction",
  ];

  for (const id of requiredSampleIds) {
    assert.ok(
      parserSmokeSamples.some((sample) => sample.id === id),
      `${id} sample missing`,
    );
  }
});

test("D0 social and entertainment future arrangements are tasks, not life events", () => {
  const socialSamples = [
    "d0_social_entertainment_future_agreement",
    "d0_social_bar_plan_with_mood",
  ];

  for (const id of socialSamples) {
    const sample = parserSmokeSamples.find((s) => s.id === id);
    assert.ok(sample, `${id} sample missing`);
    assert.ok(sample.expectedTypes.includes("task_create"));
    assert.equal(
      sample.forbiddenTypes?.includes("life_event"),
      true,
      `${id} must forbid life_event because the arrangement is still future-facing`,
    );
  }
});

test("D0 remember-word boundary distinguishes reminders from past memory", () => {
  const pastMemory = parserSmokeSamples.find(
    (sample) => sample.id === "d0_remember_past_book_is_not_task",
  );
  assert.ok(pastMemory);
  assert.equal(pastMemory.forbiddenTypes?.includes("task_create"), true);
  assert.ok(
    pastMemory.expectedTypes.includes("general_answer") ||
      (pastMemory.acceptedTypes ?? []).includes("life_event"),
  );

  const reminder = parserSmokeSamples.find(
    (sample) => sample.id === "d0_short_vague_customer_reminder",
  );
  assert.ok(reminder);
  assert.equal(reminder.expectedTypes.includes("task_create"), true);
});

test("D0 recurring goals remain task/profile candidates without pretending recurrence is implemented", () => {
  const recurringSamples = [
    "d0_recurring_english_speaking_goal",
    "d0_vibe_coding_distraction",
  ];

  for (const id of recurringSamples) {
    const sample = parserSmokeSamples.find((s) => s.id === id);
    assert.ok(sample, `${id} sample missing`);
    assert.ok(
      sample.expectedTypes.includes("task_create") ||
        (sample.acceptedTypes ?? []).includes("task_create"),
      `${id} should include task_create as a reminder/task candidate`,
    );
    assert.ok(
      sample.expectedTypes.includes("profile_candidate") ||
        (sample.acceptedTypes ?? []).includes("profile_candidate"),
      `${id} should include profile_candidate for the stable goal/preference part`,
    );
  }
});

test("Phase 5 parser prelude samples cover voice-like and mixed Chinese input", () => {
  const requiredSampleIds = [
    "phase5_voice_like_noisy_task",
    "phase5_question_with_embedded_task",
    "phase5_bare_clock_ambiguous_task",
    "phase5_voice_like_cancel_with_noise",
    "phase5_delay_with_clear_new_time",
    "phase5_vague_delay_missing_new_time",
    "phase5_voice_like_state_and_event",
  ];

  for (const id of requiredSampleIds) {
    assert.ok(
      parserSmokeSamples.some((sample) => sample.id === id),
      `${id} sample missing`,
    );
  }
});

test("Phase 5 voice-like samples do not become profile candidates", () => {
  const voiceLikeSamples = parserSmokeSamples.filter((sample) =>
    sample.id.startsWith("phase5_voice_like_"),
  );

  assert.ok(voiceLikeSamples.length >= 2);
  for (const sample of voiceLikeSamples) {
    assert.equal(
      sample.forbiddenTypes?.includes("profile_candidate"),
      true,
      `${sample.id} must forbid profile_candidate`,
    );
  }
});

test("Phase 5 mixed question sample preserves both answer and embedded task", () => {
  const sample = parserSmokeSamples.find(
    (s) => s.id === "phase5_question_with_embedded_task",
  );
  assert.ok(sample);
  assert.ok(sample.expectedTypes.includes("general_answer"));
  assert.ok(sample.expectedTypes.includes("task_create"));
  assert.equal(sample.forbiddenTypes?.includes("profile_candidate"), true);
});

test("Phase 5 task update samples cover noisy cancel and delay boundaries", () => {
  const cancelSample = parserSmokeSamples.find(
    (s) => s.id === "phase5_voice_like_cancel_with_noise",
  );
  const clearDelaySample = parserSmokeSamples.find(
    (s) => s.id === "phase5_delay_with_clear_new_time",
  );
  const vagueDelaySample = parserSmokeSamples.find(
    (s) => s.id === "phase5_vague_delay_missing_new_time",
  );

  assert.ok(cancelSample);
  assert.match(cancelSample.text, /先算了|不开了/);
  assert.ok(cancelSample.expectedTypes.includes("task_update"));

  assert.ok(clearDelaySample);
  assert.match(clearDelaySample.text, /挪到下周一下午三点/);
  assert.ok(clearDelaySample.expectedTypes.includes("task_update"));

  assert.ok(vagueDelaySample);
  assert.match(vagueDelaySample.text, /往后放一放/);
  assert.ok(vagueDelaySample.expectedTypes.includes("task_update"));
});
