import assert from "node:assert/strict";
import test from "node:test";

import { buildParserSystemPrompt } from "../src/services/parserPrompt.js";

test("parser prompt contains the required MVP parsing rules", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /JSON only/);
  assert.match(prompt, /Do not output fields outside/i);
  assert.match(prompt, /profile_candidate/);
  assert.match(prompt, /short_term_state/);
  assert.match(prompt, /source_text/);
  assert.match(prompt, /need_user_confirm/);
});

test("parser prompt states profile candidates are proposals, not active memory", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /proposal/i);
  assert.match(prompt, /must not become active memory/i);
  assert.match(prompt, /profile_candidate\.need_user_confirm.*true/i);
});

test("parser prompt allows non-saveable ordinary answers without memory items", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /ordinary questions/i);
  assert.match(prompt, /do not create saveable memory/i);
  assert.match(prompt, /items may be empty or contain only general_answer/i);
});

test("parser prompt keeps one-off lessons and cooking notes out of profile", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /cooking/i);
  assert.match(prompt, /life_event/);
  assert.match(prompt, /Do not classify one-off lessons/i);
});

test("parser prompt keeps how-to questions out of saved memories", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /how-to questions/i);
  assert.match(prompt, /general_answer/);
  assert.match(prompt, /not life_event/i);
});

test("parser prompt defines structured task_update fields", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /task_update/);
  assert.match(prompt, /update_action/);
  assert.match(prompt, /target_task_title/);
  assert.match(prompt, /target_text/);
});

test("parser prompt prevents vague task updates and vague delay times from being invented", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /vague references/i);
  assert.match(prompt, /那个事/);
  assert.match(prompt, /do not invent a target task/i);
  assert.match(prompt, /delay.*without a new time/i);
  assert.match(prompt, /do not fill due_time_iso/i);
});
