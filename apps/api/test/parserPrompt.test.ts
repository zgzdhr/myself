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
