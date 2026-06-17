import assert from "node:assert/strict";
import test from "node:test";

import {
  buildParserSystemPrompt,
  buildParserUserPrompt,
} from "../src/services/parserPrompt.js";

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

test("parser prompt preserves concrete task_update targets around generic suffixes", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /参加高考那个事取消了/);
  assert.match(prompt, /target\s+"参加高考"/i);
  assert.match(prompt, /下午开会的事情取消了/);
  assert.match(prompt, /target\s+"下午开会"/i);
  assert.match(prompt, /健身不想去了/);
  assert.match(prompt, /short_term_state/);
});

test("parser prompt contains D0 semantic classification principles instead of keyword-only rules", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /Do not classify by keywords alone/i);
  assert.match(prompt, /future arrangement/i);
  assert.match(prompt, /social or entertainment/i);
  assert.match(prompt, /task_create/);
  assert.match(prompt, /记得/);
  assert.match(prompt, /remember/i);
  assert.match(prompt, /past memory/i);
});

test("parser prompt explains life_event evidence cannot become active profile automatically", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /life_event/);
  assert.match(prompt, /evidence/i);
  assert.match(prompt, /must not automatically become profile_candidate/i);
});

test("parser prompt documents D0 short-term state subtypes as tags or semantic hints", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /location_state/);
  assert.match(prompt, /energy_state/);
  assert.match(prompt, /mood_state/);
  assert.match(prompt, /physical_state/);
  assert.match(prompt, /availability_state/);
  assert.match(prompt, /cognitive_state/);
});

test("parser prompt defines current time and optional location context rules", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /Current local time/i);
  assert.match(prompt, /今天/);
  assert.match(prompt, /明天/);
  assert.match(prompt, /Location context/i);
  assert.match(prompt, /do not guess the user's location/i);
});

test("parser prompt handles Phase 5 speech-like input and mixed intents", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /speech-like/i);
  assert.match(prompt, /filler words/i);
  assert.match(prompt, /raw natural-language user speech or text/i);
  assert.match(prompt, /First infer the user's intended meaning/i);
  assert.match(prompt, /multiple useful intents/i);
  assert.match(prompt, /split it into multiple items/i);
});

test("parser prompt distinguishes reliable and ambiguous clock times", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /明天七点/);
  assert.match(prompt, /leave due_time_iso out/i);
  assert.match(prompt, /下午三点/);
  assert.match(prompt, /晚上八点/);
  assert.match(prompt, /15:30/);
});

test("parser prompt covers Phase 5 natural cancel and delay wording", () => {
  const prompt = buildParserSystemPrompt();

  assert.match(prompt, /先算了/);
  assert.match(prompt, /撤了/);
  assert.match(prompt, /别去了/);
  assert.match(prompt, /改到/);
  assert.match(prompt, /挪到/);
  assert.match(prompt, /推到/);
});

test("parser user prompt includes current time and location context", () => {
  const prompt = buildParserUserPrompt({
    text: "附近买咖啡",
    timezone: "Asia/Shanghai",
    current_time_iso: "2026-06-08T17:15:00.000+08:00",
    input_style: "natural_language",
    location_context: {
      label: "上海市徐汇区",
      latitude: 31.188,
      longitude: 121.436,
      accuracy_meters: 50,
    },
  });

  assert.match(prompt, /Asia\/Shanghai/);
  assert.match(prompt, /2026-06-08T17:15:00\.000\+08:00/);
  assert.match(prompt, /Input style: natural_language/);
  assert.match(prompt, /上海市徐汇区/);
  assert.match(prompt, /31\.188/);
});
