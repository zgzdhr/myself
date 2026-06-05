import { z } from "zod";

export const itemTypes = [
  "task_create",
  "task_update",
  "short_term_state",
  "life_event",
  "general_answer",
  "profile_candidate",
] as const;

export const parseRequestSchema = z.object({
  text: z.string().trim().min(1),
  timezone: z.string().trim().min(1),
});

export const parseResultItemSchema = z
  .object({
    type: z.enum(itemTypes),
    title: z.string().nullable().optional(),
    content: z.string().nullable().optional(),
    description: z.string().nullable().optional(),
    detail: z.string().nullable().optional(),
    source_text: z.string().trim().min(1),
    tags: z.array(z.string()).default([]),
    confidence: z.number().min(0).max(1),
    need_user_confirm: z.boolean(),
    due_time_text: z.string().nullable().optional(),
    due_time_iso: z.string().nullable().optional(),
    target_task_title: z.string().nullable().optional(),
    target_text: z.string().nullable().optional(),
    update_action: z
      .enum(["complete", "cancel", "delay", "edit"])
      .optional(),
    valid_days: z.number().int().positive().optional(),
    expires_at: z.string().datetime().optional(),
    priority: z.enum(["low", "medium", "high"]).optional(),
    project: z.string().nullable().optional(),
  })
  .strict()
  .refine(
    (item) =>
      item.type !== "profile_candidate" || item.need_user_confirm === true,
    {
      message: "profile_candidate items must require user confirmation",
      path: ["need_user_confirm"],
    },
  );

export const parseResultSchema = z
  .object({
    user_reply: z.string(),
    input_summary: z.string(),
    intent_types: z.array(z.enum(itemTypes)),
    items: z.array(parseResultItemSchema),
    memory_candidates: z.array(z.unknown()).default([]),
    safety_flags: z.array(z.string()).default([]),
    need_follow_up_question: z.boolean().default(false),
    follow_up_question: z.string().nullable().default(null),
  })
  .strict();

export type ParseRequest = z.infer<typeof parseRequestSchema>;
export type ParseResult = z.infer<typeof parseResultSchema>;
