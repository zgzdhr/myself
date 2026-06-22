import type { ReviewRequest } from "../schemas/reviewResultSchema.js";

export const REVIEW_PROMPT_VERSION = "review-daily-v1";

export function buildReviewSystemPrompt(): string {
  return [
    "You are generating a daily review for a personal memory and action app.",
    "The user sees, edits, deletes, and regenerates this review.",
    "Use only the source records in the request and the user's optional note.",
    "Do not invent events, tasks, long-term patterns, health claims, or user traits.",
    "Do not turn one day of data into a long-term profile.",
    "Write in concise, warm Chinese.",
    "Include some sincere encouragement, but avoid exaggerated praise.",
    "Analyze today's shortcomings as improvable next steps, not as blame.",
    "Task guidance should suggest how to handle tasks; it must not claim tasks were changed.",
    "Return JSON only.",
  ].join("\n");
}

export function buildReviewUserPrompt(request: ReviewRequest): string {
  return JSON.stringify(
    {
      task: "Generate one daily review JSON object.",
      output_schema: {
        title: "Short title for the review.",
        daily_summary: "What happened today, bounded by sources.",
        encouragement: "Warm encouragement for the user.",
        improvement_notes: "Concrete shortcomings or possible improvements from today.",
        task_guidance: "Lightweight advice for handling tasks tomorrow or later.",
        open_items: ["Unresolved item strings."],
        source_refs: [
          {
            source_table:
              "tasks | short_term_states | life_events | profile_items",
            source_record_id: "id from input sources",
          },
        ],
        confidence: "0 to 1",
        uncertainty_notes: ["Anything uncertain or missing."],
      },
      rules: [
        "daily_summary should be 2-5 short Chinese sentences.",
        "encouragement should be 1-2 short Chinese sentences.",
        "improvement_notes should be specific and actionable.",
        "task_guidance should not create, complete, cancel, or reschedule tasks.",
        "source_refs must only include source ids present in this request.",
        "If there is not enough data, say so honestly and rely on user_note if present.",
      ],
      request,
    },
    null,
    2,
  );
}
