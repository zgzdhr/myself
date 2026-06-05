import assert from "node:assert/strict";
import test from "node:test";

import { buildParserSystemPrompt } from "../src/services/parserPrompt.js";

test("parser prompt contains the required MVP parsing rules", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /JSON only/);
  assert.match(prompt, /profile_candidate/);
  assert.match(prompt, /short_term_state/);
  assert.match(prompt, /source_text/);
  assert.match(prompt, /need_user_confirm/);
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
