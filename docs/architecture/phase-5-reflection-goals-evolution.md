# Phase 5 Reflection, Goals, and Evolution Roadmap

Date: 2026-06-13

Status: planning document only. This document records product direction and
architecture boundaries for future sessions. It does not implement database,
Flutter, API, desktop, or AI-provider changes.

## 1. Current Architecture Read

The current project is not overbuilt or chaotic. Its complexity mostly comes
from trust boundaries that are appropriate for a personal memory app:

- user-visible confirmation before long-term profile memory becomes active;
- local-first storage;
- schema validation before AI output enters the app;
- safe deletion and undo paths;
- ContextBuilder rules that avoid sending all private memory to the model.

The main architectural pressure is different:

> The `/parse` pipeline is starting to carry too many expectations.

Today `/parse` is a structured memory parser. It is good at turning a natural
language input into MVP item types such as `task_create`, `short_term_state`,
`life_event`, and `profile_candidate`.

It should not become the only place for every intelligent behavior. Reflection,
learning-path guidance, customer analysis, knowledge-base work, and long-term
self-evolution need different prompts, schemas, context selection rules, and
user controls.

## 2. Product Direction

The app should continue to be built step by step, but the long-term product
direction should include these ideas:

- daily reflection: the user says what happened today and what they learned;
- AI cleanup: speech-like noisy input is summarized into useful notes;
- goal alignment: today's progress is connected to confirmed user goals;
- next-step guidance: the app proposes the next useful learning or action step;
- desktop analysis: the phone is good for fast capture, while desktop is better
  for reading deeper analysis, goals, paths, and summaries;
- controlled knowledge base: useful records and summaries can become a personal
  knowledge layer without silently becoming personality truth;
- gradual self-evolution: the app becomes more useful as it accumulates
  user-confirmed goals, progress, preferences, and repeated patterns.

The first product principle remains:

> If a sentence has future value, the app should decide where it belongs, how
> long it should matter, and when it should be brought back.

## 3. What Self-Evolution Means Here

In this project, "self-evolution" should not mean an autonomous AI that rewrites
the user's life plan or silently changes long-term profile.

It should mean:

```text
User inputs real daily experience
→ AI summarizes and extracts useful structure
→ user confirms important records
→ the app accumulates goals, progress, blockers, preferences, and summaries
→ later suggestions use this confirmed context
→ advice gradually becomes more relevant and better explained
```

Self-evolution is therefore a product loop, not a magic model feature.

Important constraints:

- confirmed `profile_items` outrank summaries and candidates;
- `profile_candidate` and `profile_candidate_summary` must require review;
- one-time events or moods must not become stable personality claims;
- AI-generated next steps should be suggestions first, not automatically
  scheduled tasks;
- any memory that can influence future suggestions must be visible, editable,
  and deletable.

## 4. AI Capability Split

Future AI capabilities should be split by job instead of being added to the
current parser prompt.

Suggested service boundaries:

```text
/parse
  Turns user input into structured memory/action items.
  Output must stay schema-validated and conservative.

/review
  Generates daily or weekly reflection summaries from visible source records.
  Output should cite source records and preserve uncertainty.

/coach
  Aligns confirmed goals, recent progress, blockers, and summaries.
  Output gives 1-3 next-step suggestions with reasons.

/memory
  Helps view, edit, delete, restore, or inspect memory records and summaries.
  Ambiguous operations must ask for confirmation.
```

This split avoids making `/parse` a single overloaded "AI brain".

## 5. Phase 5 Recommended Scope

Phase 5 should focus on reflection and goal alignment, not a full desktop
knowledge base or automatic self-evolution.

Recommended order:

1. Phase 5A: daily reflection summary
   - User can generate a concise summary of today's visible records.
   - Use existing `tasks`, `short_term_states`, and `life_events` first.
   - Store summary as user-visible memory.
   - Allow edit, delete, and regenerate.

2. Phase 5B: learning goal records
   - Add explicit user-confirmed learning goals, such as UI design or Flutter.
   - Do not infer long-term goals from one sentence without confirmation.

3. Phase 5C: learning progress records
   - Extract daily learning progress from reflection input.
   - Connect progress to confirmed learning goals when confidence is high.
   - Ask user to confirm when mapping is uncertain.

4. Phase 5D: next-step suggestions
   - Use confirmed goals, recent progress, blockers, and summaries.
   - Generate a small set of next steps with explanations.
   - Do not auto-create tasks unless the user chooses one.

5. Phase 5E: controllable memory management improvements
   - Show which summaries and goals can affect suggestions.
   - Support delete, archive, restore, and source inspection.

## 6. Desktop Direction

Desktop is useful, but it should not be introduced as a complete second product
too early.

Near-term desktop goal:

> Build a read-heavy analysis surface for reflection, goals, progress, and
> suggestion explanations.

Phone-first responsibilities:

- fast capture;
- voice/text input;
- quick confirmation;
- lightweight today view.

Desktop-first responsibilities:

- daily and weekly reflection reading;
- learning-goal overview;
- progress and blockers;
- source-backed AI analysis;
- memory and summary management;
- later knowledge-base navigation.

The safest first desktop implementation could be a small web app sharing the
same API contracts and data model concepts, instead of a full native desktop
client.

## 7. Knowledge Base Boundary

Tools like Obsidian or IMA are useful references, but this app should not become
a generic note archive first.

The app's knowledge base should be:

- source-backed;
- personal-goal-aware;
- connected to actions, reflections, and decisions;
- controlled by memory visibility and deletion rules;
- useful for "what should I do/learn next", not only for storing notes.

Do not add vector search or broad RAG before the app has clear source records,
summaries, and user controls.

## 8. Current Technical Risks To Watch

Current code is serviceable, but future work should avoid adding more behavior
to already-large files without splitting responsibilities.

Main pressure points:

- `apps/mobile/lib/features/extracted_items/extracted_items_controller.dart`
  already mixes submit, persistence, auto-save, edit, undo, and task-update
  matching.
- `apps/mobile/lib/features/input/input_screen.dart` mixes input UI with pending
  batch and task-update confirmation flows.
- `apps/mobile/lib/features/home/home_screen.dart` mixes home layout, debug date
  controls, and follow-up panels.
- `apps/api/src/services/parserPrompt.ts` is intentionally conservative and
  rule-heavy; do not keep adding review/coach behavior to it.

Before implementing Phase 5, consider extracting smaller services around:

- official record creation;
- task update resolution;
- reflection summary generation;
- goal/progress matching;
- suggestion generation.

## 9. Parser Quality Notes

The current parser may feel rigid because the API uses a low-temperature
structured JSON mode with a conservative prompt and a fast model.

This is good for safe memory extraction, but not enough for nuanced reflection
or coaching.

Future options:

- keep `/parse` conservative;
- use a separate prompt/model configuration for `/review`;
- use a separate prompt/model configuration for `/coach`;
- allow richer but still source-bounded output for analysis;
- keep schema validation for every AI output that becomes app data.

Voice input also needs tolerance for transcription noise. The review/coach
prompts should explicitly handle filler words, repeated phrases, and unclear
speech fragments without over-saving them.

## 10. Do Not Do Yet

Do not jump directly to:

- full desktop client;
- broad knowledge-base product;
- vector search;
- automatic profile evolution;
- autonomous agent planning;
- automatic goal rewriting;
- deep customer-analysis CRM;
- cloud sync as a prerequisite for Phase 5;
- replacing the MVP parser with a single larger "all-purpose" prompt.

The next useful step is smaller:

```text
daily reflection summary
→ explicit learning goals
→ progress linked to goals
→ source-backed next-step suggestions
```

