import type { PlanRequest } from "../schemas/planResultSchema.js";

export const PLAN_PROMPT_VERSION = "plan-daily-v1";

export function buildPlanSystemPrompt(): string {
  return [
    "You are the time planning module for a personal memory and action app.",
    "Your job is to create an editable single-day time-blocking draft.",
    "The user must stay in control: never mark tasks completed, cancelled, postponed, or changed.",
    "Use tasks, current states, confirmed profile items, and recent daily summaries as context.",
    "Prefer realistic blocks with buffers and breaks over an overfilled schedule.",
    "Return only valid JSON that matches the requested schema.",
  ].join("\n");
}

export function buildPlanUserPrompt(request: PlanRequest): string {
  return [
    `Prompt version: ${PLAN_PROMPT_VERSION}`,
    `Timezone: ${request.timezone}`,
    `Plan date: ${request.plan_date}`,
    `Current time: ${request.current_time_iso}`,
    `Planning window: ${request.day_start_hour}:00-${request.day_end_hour}:00`,
    "",
    "User note:",
    request.user_note || "(empty)",
    "",
    "Output JSON shape:",
    JSON.stringify(
      {
        title: "string",
        overview: "string",
        blocks: [
          {
            title: "string",
            block_type: "task | break | buffer | personal | review",
            start_time_iso: "ISO datetime",
            end_time_iso: "ISO datetime",
            task_id: "task id or null",
            note: "short editable note",
            reason: "why this block is placed here",
            confidence: 0.7,
            source_refs: [
              {
                source_table: "tasks | short_term_states | profile_items | summaries",
                source_record_id: "id",
              },
            ],
          },
        ],
        unscheduled_task_ids: ["task id"],
        suggestions: ["string"],
        source_refs: [
          {
            source_table: "tasks | short_term_states | profile_items | summaries",
            source_record_id: "id",
          },
        ],
        confidence: 0.7,
        uncertainty_notes: ["string"],
      },
      null,
      2,
    ),
    "",
    "Planning rules:",
    "- Only create a draft. Do not claim that any task was changed.",
    "- Keep all blocks within the planning window and on the plan date.",
    "- Use active tasks first. Completed or cancelled tasks are context only and should not receive work blocks.",
    "- If there are too many tasks, schedule the most time-sensitive or high-priority ones and put the rest in unscheduled_task_ids.",
    "- Add short buffer or break blocks when the day would otherwise be too dense.",
    "- If the user is tired or overloaded, make the plan lighter and explain why.",
    "- Include source_refs for the records that influenced each block when possible.",
    "- Keep Chinese user-facing text concise, gentle, and practical.",
    "",
    "Request data:",
    JSON.stringify(request, null, 2),
  ].join("\n");
}
