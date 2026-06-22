import { z } from "zod";

const isoDateTimeSchema = z.string().refine(
  (value) => !Number.isNaN(Date.parse(value)),
  "Expected an ISO-like date time string that JavaScript Date can parse",
);

const reviewTaskSchema = z
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

const reviewStateSchema = z
  .object({
    id: z.string().trim().min(1),
    content: z.string().trim().min(1),
    status: z.string().trim().min(1),
  })
  .strict();

const reviewLifeEventSchema = z
  .object({
    id: z.string().trim().min(1),
    content: z.string().trim().min(1),
    status: z.string().trim().min(1),
  })
  .strict();

const reviewProfileItemSchema = z
  .object({
    id: z.string().trim().min(1),
    content: z.string().trim().min(1),
    category: z.string().nullable().optional(),
    status: z.string().trim().min(1),
  })
  .strict();

export const reviewRequestSchema = z
  .object({
    timezone: z.string().trim().min(1),
    review_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    current_time_iso: isoDateTimeSchema,
    user_note: z.string().trim().max(2000).optional().default(""),
    tasks: z.array(reviewTaskSchema).max(30).default([]),
    short_term_states: z.array(reviewStateSchema).max(20).default([]),
    life_events: z.array(reviewLifeEventSchema).max(30).default([]),
    profile_items: z.array(reviewProfileItemSchema).max(10).default([]),
  })
  .strict();

export const reviewSourceRefSchema = z
  .object({
    source_table: z.enum(["tasks", "short_term_states", "life_events", "profile_items"]),
    source_record_id: z.string().trim().min(1),
  })
  .strict();

export const reviewResultSchema = z
  .object({
    title: z.string().trim().min(1),
    daily_summary: z.string().trim().min(1),
    encouragement: z.string().trim().min(1),
    improvement_notes: z.string().trim().min(1),
    task_guidance: z.string().trim().min(1),
    open_items: z.array(z.string().trim().min(1)).max(8).default([]),
    source_refs: z.array(reviewSourceRefSchema).default([]),
    confidence: z.number().min(0).max(1).default(0.7),
    uncertainty_notes: z.array(z.string()).default([]),
  })
  .strict();

export type ReviewRequest = z.infer<typeof reviewRequestSchema>;
export type ReviewResult = z.infer<typeof reviewResultSchema>;
