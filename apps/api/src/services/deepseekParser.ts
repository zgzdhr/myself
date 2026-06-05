import {
  parseResultSchema,
  type ParseRequest,
  type ParseResult,
} from "../schemas/parseResultSchema.js";
import { buildParserSystemPrompt, buildParserUserPrompt } from "./parserPrompt.js";

type FetchLike = (
  input: string | URL | Request,
  init?: RequestInit,
) => Promise<Response>;

type DeepSeekParserConfig = {
  apiKey?: string;
  baseUrl?: string;
  model?: string;
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

export type ParserServiceErrorCode =
  | "missing_api_key"
  | "deepseek_request_failed"
  | "deepseek_http_error"
  | "empty_parse_result"
  | "invalid_parse_result";

export class ParserServiceError extends Error {
  readonly code: ParserServiceErrorCode;
  readonly statusCode: number;
  readonly details?: unknown;

  constructor(
    code: ParserServiceErrorCode,
    statusCode: number,
    message: string,
    details?: unknown,
  ) {
    super(message);
    this.name = "ParserServiceError";
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

export function createDeepSeekParser(config: DeepSeekParserConfig = {}) {
  return async function parseWithDeepSeek(
    request: ParseRequest,
  ): Promise<ParseResult> {
    const apiKey = (config.apiKey ?? process.env.DEEPSEEK_API_KEY ?? "").trim();

    if (isMissingApiKey(apiKey)) {
      throw new ParserServiceError(
        "missing_api_key",
        503,
        "DeepSeek API key is missing. Set DEEPSEEK_API_KEY on the API server.",
      );
    }

    const fetchFn = config.fetchFn ?? fetch;
    const baseUrl = normalizeBaseUrl(
      config.baseUrl ?? process.env.DEEPSEEK_BASE_URL ?? "https://api.deepseek.com",
    );
    const model =
      config.model ?? process.env.DEEPSEEK_MODEL ?? "deepseek-v4-flash";
    const timeoutMs = config.timeoutMs ?? 20_000;

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
          request,
          signal: controller.signal,
        });
      } catch (error) {
        if (error instanceof ParserServiceError) throw error;
        throw new ParserServiceError(
          "deepseek_request_failed",
          503,
          "DeepSeek API request failed before a response was received.",
        );
      } finally {
        clearTimeout(timer);
      }

      const parsedJson = tryParseJson(content);

      if (!parsedJson.success) {
        lastError = {
          attempt,
          reason: "invalid_json",
          message: parsedJson.message,
        };
        continue;
      }

      const parsedResult = parseResultSchema.safeParse(parsedJson.value);

      if (parsedResult.success) {
        return parsedResult.data;
      }

      lastError = {
        attempt,
        reason: "invalid_schema",
        issues: parsedResult.error.issues,
      };
    }

    throw new ParserServiceError(
      "invalid_parse_result",
      502,
      "DeepSeek parser returned invalid JSON or a result that does not match the parser schema.",
      lastError,
    );
  };
}

function isMissingApiKey(apiKey: string): boolean {
  return !apiKey || apiKey === "replace_with_your_key";
}

function normalizeBaseUrl(baseUrl: string): string {
  return baseUrl.replace(/\/+$/, "");
}

async function callDeepSeek({
  apiKey,
  baseUrl,
  fetchFn,
  model,
  request,
  signal,
}: {
  apiKey: string;
  baseUrl: string;
  fetchFn: FetchLike;
  model: string;
  request: ParseRequest;
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
          { role: "system", content: buildParserSystemPrompt() },
          { role: "user", content: buildParserUserPrompt(request) },
        ],
        response_format: { type: "json_object" },
        thinking: { type: "disabled" },
        stream: false,
        temperature: 0.1,
        max_tokens: 1800,
      }),
    });
  } catch {
    throw new ParserServiceError(
      "deepseek_request_failed",
      503,
      "DeepSeek API request failed before a response was received.",
    );
  }

  if (!response.ok) {
    throw new ParserServiceError(
      "deepseek_http_error",
      response.status >= 500 ? 503 : 502,
      "DeepSeek API returned an unsuccessful response.",
      { status: response.status },
    );
  }

  const payload = (await response.json()) as DeepSeekChatResponse;
  const content = payload.choices?.[0]?.message?.content;

  if (!content?.trim()) {
    throw new ParserServiceError(
      "empty_parse_result",
      502,
      "DeepSeek API returned an empty parser response.",
    );
  }

  return content;
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
