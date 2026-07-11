import type { PlanRequest, PlanResult } from "../schemas/planResultSchema.js";
import type {
  ReviewRequest,
  ReviewResult,
} from "../schemas/reviewResultSchema.js";

type GuardResult =
  | { ok: true }
  | {
      ok: false;
      issues: string[];
    };

type SourceRef = {
  source_table: string;
  source_record_id: string;
};

export function validateReviewResultForRequest(
  request: ReviewRequest,
  result: ReviewResult,
): GuardResult {
  const allowedSources = new Map<string, Set<string>>([
    ["tasks", new Set(request.tasks.map((item) => item.id))],
    [
      "short_term_states",
      new Set(request.short_term_states.map((item) => item.id)),
    ],
    ["life_events", new Set(request.life_events.map((item) => item.id))],
    ["profile_items", new Set(request.profile_items.map((item) => item.id))],
  ]);

  return validateSourceRefs(result.source_refs, allowedSources, "source_refs");
}

export function validatePlanResultForRequest(
  request: PlanRequest,
  result: PlanResult,
): GuardResult {
  const issues: string[] = [];
  const allowedSources = new Map<string, Set<string>>([
    ["tasks", new Set(request.tasks.map((item) => item.id))],
    [
      "short_term_states",
      new Set(request.short_term_states.map((item) => item.id)),
    ],
    ["profile_items", new Set(request.profile_items.map((item) => item.id))],
    ["summaries", new Set(request.recent_summaries.map((item) => item.id))],
  ]);
  const activeTaskIds = new Set(
    request.tasks
      .filter(
        (task) => task.status === "confirmed" && task.task_status === "active",
      )
      .map((task) => task.id),
  );

  const rootSources = validateSourceRefs(
    result.source_refs,
    allowedSources,
    "source_refs",
  );
  if (!rootSources.ok) issues.push(...rootSources.issues);

  for (const [index, block] of result.blocks.entries()) {
    const path = `blocks[${index}]`;
    const blockSources = validateSourceRefs(
      block.source_refs,
      allowedSources,
      `${path}.source_refs`,
    );
    if (!blockSources.ok) issues.push(...blockSources.issues);

    if (block.block_type === "task" && block.task_id == null) {
      issues.push(`${path}.task_id must identify an active input task.`);
    } else if (block.task_id != null && !activeTaskIds.has(block.task_id)) {
      issues.push(`${path}.task_id is not an active task in this request.`);
    }

    const rangeIssue = validatePlanBlockTimeRange({
      planDate: request.plan_date,
      timezone: request.timezone,
      dayStartHour: request.day_start_hour,
      dayEndHour: request.day_end_hour,
      startTimeIso: block.start_time_iso,
      endTimeIso: block.end_time_iso,
      path,
    });
    if (rangeIssue != null) issues.push(rangeIssue);
  }

  for (const taskId of result.unscheduled_task_ids) {
    if (!activeTaskIds.has(taskId)) {
      issues.push("unscheduled_task_ids must only contain active input task ids.");
      break;
    }
  }

  return issues.length === 0 ? { ok: true } : { ok: false, issues };
}

function validateSourceRefs(
  refs: SourceRef[],
  allowedSources: Map<string, Set<string>>,
  path: string,
): GuardResult {
  const issues: string[] = [];
  for (const [index, ref] of refs.entries()) {
    const allowedIds = allowedSources.get(ref.source_table);
    if (allowedIds == null || !allowedIds.has(ref.source_record_id)) {
      issues.push(
        `${path}[${index}] must reference an id from the current request.`,
      );
    }
  }
  return issues.length === 0 ? { ok: true } : { ok: false, issues };
}

function validatePlanBlockTimeRange({
  planDate,
  timezone,
  dayStartHour,
  dayEndHour,
  startTimeIso,
  endTimeIso,
  path,
}: {
  planDate: string;
  timezone: string;
  dayStartHour: number;
  dayEndHour: number;
  startTimeIso: string;
  endTimeIso: string;
  path: string;
}): string | null {
  try {
    const start = zonedDateTimeParts(startTimeIso, timezone);
    const end = zonedDateTimeParts(endTimeIso, timezone);
    const startsOnPlanDate = start.date === planDate;
    const endsOnPlanDate = end.date === planDate;
    const startsInWindow = start.minutes >= dayStartHour * 60;
    const endsInWindow = end.minutes <= dayEndHour * 60;

    if (
      !startsOnPlanDate ||
      !endsOnPlanDate ||
      !startsInWindow ||
      !endsInWindow
    ) {
      return `${path} must stay on ${planDate} within the requested planning window.`;
    }
    return null;
  } catch {
    return `${path} has an invalid timezone-aware time range.`;
  }
}

function zonedDateTimeParts(
  isoTime: string,
  timezone: string,
): { date: string; minutes: number } {
  const date = new Date(isoTime);
  if (Number.isNaN(date.getTime())) {
    throw new Error("Invalid date");
  }

  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const values = Object.fromEntries(
    parts
      .filter((part) => part.type !== "literal")
      .map((part) => [part.type, part.value]),
  );
  const year = values.year;
  const month = values.month;
  const day = values.day;
  const hour = Number(values.hour);
  const minute = Number(values.minute);

  if (!year || !month || !day || Number.isNaN(hour) || Number.isNaN(minute)) {
    throw new Error("Missing date parts");
  }

  return { date: `${year}-${month}-${day}`, minutes: hour * 60 + minute };
}
