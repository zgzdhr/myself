import {
  planResultSchema,
  type PlanRequest,
  type PlanResult,
} from "../schemas/planResultSchema.js";
import {
  PLAN_PROMPT_VERSION,
  buildPlanSystemPrompt,
  buildPlanUserPrompt,
} from "./planPrompt.js";

type FetchLike = (
  input: string | URL | Request,
  init?: RequestInit,
) => Promise<Response>;

type DeepSeekPlanConfig = {
  apiKey?: string;
  baseUrl?: string;
  model?: string;
  temperature?: number;
  fetchFn?: FetchLike;
  timeoutMs?: number;
};

type DeepSeekChatResponse = {
  choices?: Array<{
    message?: {
      content?: string | null;
    };
  }>;
};

export type PlanServiceErrorCode =
  | "missing_api_key"
  | "deepseek_request_failed"
  | "deepseek_http_error"
  | "empty_plan_result"
  | "invalid_plan_result";

export class PlanServiceError extends Error {
  readonly code: PlanServiceErrorCode;
  readonly statusCode: number;
  readonly details?: unknown;

  constructor(
    code: PlanServiceErrorCode,
    statusCode: number,
    message: string,
    details?: unknown,
  ) {
    super(message);
    this.name = "PlanServiceError";
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
  }

  toLogEntry(requestId: string) {
    return {
      requestId,
      errorType: this.code,
      statusCode: this.statusCode,
    };
  }
}

export function createDeepSeekPlan(config: DeepSeekPlanConfig = {}) {
  return async function planWithDeepSeek(
    request: PlanRequest,
  ): Promise<PlanResult> {
    const apiKey = (config.apiKey ?? process.env.DEEPSEEK_API_KEY ?? "").trim();

    if (!apiKey || apiKey === "replace_with_your_key") {
      throw new PlanServiceError(
        "missing_api_key",
        503,
        "DeepSeek API key is missing. Set DEEPSEEK_API_KEY on the API server.",
      );
    }

    const fetchFn = config.fetchFn ?? fetch;
    const baseUrl = (config.baseUrl ?? process.env.DEEPSEEK_BASE_URL ?? "https://api.deepseek.com").replace(/\/+$/, "");
    const model =
      config.model ?? process.env.DEEPSEEK_PLAN_MODEL ?? process.env.DEEPSEEK_MODEL ?? "deepseek-v4-flash";
    const temperature = config.temperature ?? readPlanTemperatureFromEnv() ?? 0.45;
    const timeoutMs = config.timeoutMs ?? 25_000;

    let lastError: unknown;

    for (let attempt = 1; attempt <= 2; attempt += 1) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);

      let content: string;
      try {
        content = await callDeepSeek({
          apiKey,
          baseUrl,
          fetchFn,
          model,
          temperature,
          request,
          signal: controller.signal,
        });
      } catch (error) {
        if (error instanceof PlanServiceError) throw error;
        throw new PlanServiceError(
          "deepseek_request_failed",
          503,
          "DeepSeek API request failed before a response was received.",
        );
      } finally {
        clearTimeout(timer);
      }

      const parsedJson = tryParseJson(content);

      if (!parsedJson.success) {
        lastError = { attempt, reason: "invalid_json", message: parsedJson.message };
        continue;
      }

      const parsedResult = planResultSchema.safeParse(parsedJson.value);

      if (parsedResult.success) {
        return parsedResult.data;
      }

      lastError = {
        attempt,
        reason: "invalid_schema",
        issues: parsedResult.error.issues,
      };
    }

    throw new PlanServiceError(
      "invalid_plan_result",
      502,
      "DeepSeek plan returned invalid JSON or a result that does not match the plan schema.",
      lastError,
    );
  };
}

async function callDeepSeek({
  apiKey,
  baseUrl,
  fetchFn,
  model,
  temperature,
  request,
  signal,
}: {
  apiKey: string;
  baseUrl: string;
  fetchFn: FetchLike;
  model: string;
  temperature: number;
  request: PlanRequest;
  signal?: AbortSignal;
}): Promise<string> {
  let response: Response;

  try {
    response = await fetchFn(`${baseUrl}/chat/completions`, {
      method: "POST",
      ...(signal ? { signal } : {}),
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: buildPlanSystemPrompt() },
          { role: "user", content: buildPlanUserPrompt(request) },
        ],
        response_format: { type: "json_object" },
        thinking: { type: "disabled" },
        stream: false,
        temperature,
        max_tokens: 2200,
      }),
    });
  } catch {
    throw new PlanServiceError(
      "deepseek_request_failed",
      503,
      "DeepSeek API request failed before a response was received.",
    );
  }

  if (!response.ok) {
    throw new PlanServiceError(
      "deepseek_http_error",
      response.status >= 500 ? 503 : 502,
      "DeepSeek API returned an unsuccessful response.",
      { status: response.status },
    );
  }

  const payload = (await response.json()) as DeepSeekChatResponse;
  const content = payload.choices?.[0]?.message?.content;

  if (!content?.trim()) {
    throw new PlanServiceError(
      "empty_plan_result",
      502,
      "DeepSeek API returned an empty plan response.",
    );
  }

  return content;
}

function readPlanTemperatureFromEnv(): number | undefined {
  const rawValue = process.env.DEEPSEEK_PLAN_TEMPERATURE?.trim();
  if (!rawValue) return undefined;

  const parsed = Number(rawValue);
  if (!Number.isFinite(parsed)) return undefined;

  return Math.min(Math.max(parsed, 0), 1);
}

function tryParseJson(
  value: string,
): { success: true; value: unknown } | { success: false; message: string } {
  try {
    return { success: true, value: JSON.parse(value) };
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : "Unknown JSON parse error",
    };
  }
}

export { PLAN_PROMPT_VERSION };
