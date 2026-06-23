import { z } from "zod";

const isoDateTimeSchema = z.string().refine(
  (value) => !Number.isNaN(Date.parse(value)),
  "Expected an ISO-like date time string that JavaScript Date can parse",
);

const planTaskSchema = z
  .object({
    id: z.string().trim().min(1),
    title: z.string().trim().min(1),
    description: z.string().nullable().optional(),
    due_time_text: z.string().nullable().optional(),
    due_time_iso: isoDateTimeSchema.nullable().optional(),
    priority: z.enum(["low", "medium", "high"]).optional(),
    task_status: z.enum(["active", "completed", "cancelled"]),
    status: z.string().trim().min(1),
  })
  .strict();

const planStateSchema = z
  .object({
    id: z.string().trim().min(1),
    content: z.string().trim().min(1),
    status: z.string().trim().min(1),
  })
  .strict();

const planProfileItemSchema = z
  .object({
    id: z.string().trim().min(1),
    content: z.string().trim().min(1),
    category: z.string().nullable().optional(),
    status: z.string().trim().min(1),
  })
  .strict();

const planSummarySchema = z
  .object({
    id: z.string().trim().min(1),
    title: z.string().trim().min(1),
    content: z.string().trim().min(1),
    encouragement: z.string().nullable().optional(),
    improvement_notes: z.string().nullable().optional(),
    task_guidance: z.string().nullable().optional(),
    time_range_start: isoDateTimeSchema,
  })
  .strict();

export const planRequestSchema = z
  .object({
    timezone: z.string().trim().min(1),
    plan_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    current_time_iso: isoDateTimeSchema,
    user_note: z.string().trim().max(2000).optional().default(""),
    day_start_hour: z.number().int().min(0).max(23).default(8),
    day_end_hour: z.number().int().min(1).max(24).default(22),
    tasks: z.array(planTaskSchema).max(40).default([]),
    short_term_states: z.array(planStateSchema).max(20).default([]),
    profile_items: z.array(planProfileItemSchema).max(10).default([]),
    recent_summaries: z.array(planSummarySchema).max(5).default([]),
  })
  .strict()
  .refine((value) => value.day_start_hour < value.day_end_hour, {
    message: "day_start_hour must be earlier than day_end_hour",
  });

export const planSourceRefSchema = z
  .object({
    source_table: z.enum(["tasks", "short_term_states", "profile_items", "summaries"]),
    source_record_id: z.string().trim().min(1),
  })
  .strict();

export const planBlockSchema = z
  .object({
    title: z.string().trim().min(1),
    block_type: z.enum(["task", "break", "buffer", "personal", "review"]),
    start_time_iso: isoDateTimeSchema,
    end_time_iso: isoDateTimeSchema,
    task_id: z.string().trim().min(1).nullable().optional(),
    note: z.string().trim().max(500).optional().default(""),
    reason: z.string().trim().min(1),
    confidence: z.number().min(0).max(1).default(0.7),
    source_refs: z.array(planSourceRefSchema).max(8).default([]),
  })
  .strict()
  .refine(
    (value) => Date.parse(value.start_time_iso) < Date.parse(value.end_time_iso),
    { message: "start_time_iso must be earlier than end_time_iso" },
  );

export const planResultSchema = z
  .object({
    title: z.string().trim().min(1),
    overview: z.string().trim().min(1),
    blocks: z.array(planBlockSchema).min(1).max(16),
    unscheduled_task_ids: z.array(z.string().trim().min(1)).max(20).default([]),
    suggestions: z.array(z.string().trim().min(1)).max(8).default([]),
    source_refs: z.array(planSourceRefSchema).max(20).default([]),
    confidence: z.number().min(0).max(1).default(0.7),
    uncertainty_notes: z.array(z.string()).default([]),
  })
  .strict();

export type PlanRequest = z.infer<typeof planRequestSchema>;
export type PlanResult = z.infer<typeof planResultSchema>;
