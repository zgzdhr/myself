import assert from "node:assert/strict";
import test from "node:test";

import {
  createDeepSeekParser,
  ParserServiceError,
} from "../src/services/deepseekParser.js";
import { parseRequestSchema } from "../src/schemas/parseResultSchema.js";

const currentTimeIso = "2026-06-08T17:15:00.000+08:00";
const parseRequest = {
  text: "明天联系王总",
  timezone: "Asia/Shanghai",
  current_time_iso: currentTimeIso,
  input_style: "natural_language" as const,
};

test("rejects input longer than 2000 characters", () => {
  const longText = "测试".repeat(1001); // 2002 chars
  const result = parseRequestSchema.safeParse({
    text: longText,
    timezone: "Asia/Shanghai",
    current_time_iso: currentTimeIso,
  });
  assert.equal(result.success, false);
  if (!result.success) {
    const textIssue = result.error.issues.find(
      (i) => i.path[0] === "text",
    );
    assert.ok(textIssue, "expected a validation issue on `text`");
  }
});

test("accepts input at exactly 2000 characters", () => {
  const text = "测试".repeat(1000); // exactly 2000 chars
  const result = parseRequestSchema.safeParse({
    text,
    timezone: "Asia/Shanghai",
    current_time_iso: currentTimeIso,
  });
  assert.equal(result.success, true);
});

const validParseResult = {
  user_reply: "我帮你整理出了一个任务。",
  input_summary: "明天联系王总。",
  intent_types: ["task_create"],
  items: [
    {
      type: "task_create",
      title: "联系王总",
      source_text: "明天联系王总",
      tags: ["work"],
      confidence: 0.9,
      need_user_confirm: true,
    },
  ],
};

function jsonCompletion(content: string): Response {
  return new Response(
    JSON.stringify({
      choices: [
        {
          message: {
            content,
          },
        },
      ],
    }),
    {
      status: 200,
      headers: { "content-type": "application/json" },
    },
  );
}

test("returns a clear error when the DeepSeek API key is missing", async () => {
  const parser = createDeepSeekParser({ apiKey: "" });

  await assert.rejects(
    () => parser(parseRequest),
    (error) => {
      assert.equal(error instanceof ParserServiceError, true);
      assert.equal((error as ParserServiceError).code, "missing_api_key");
      return true;
    },
  );
});

test("treats the example placeholder DeepSeek API key as missing", async () => {
  const parser = createDeepSeekParser({ apiKey: "replace_with_your_key" });

  await assert.rejects(
    () => parser(parseRequest),
    (error) => {
      assert.equal(error instanceof ParserServiceError, true);
      assert.equal((error as ParserServiceError).code, "missing_api_key");
      return true;
    },
  );
});

test("retries once when DeepSeek returns invalid JSON, then validates the result", async () => {
  const calls: RequestInit[] = [];
  const responses = [
    jsonCompletion("not json"),
    jsonCompletion(JSON.stringify(validParseResult)),
  ];
  const fetchFn = async (_url: string | URL | Request, init?: RequestInit) => {
    if (init) {
      calls.push(init);
    }
    return responses.shift() ?? jsonCompletion(JSON.stringify(validParseResult));
  };
  const parser = createDeepSeekParser({ apiKey: "test-key", fetchFn });

  const result = await parser(parseRequest);

  assert.equal(calls.length, 2);
  assert.equal(result.items[0]?.type, "task_create");

  const firstBody = JSON.parse(String(calls[0]?.body));
  assert.equal(firstBody.response_format.type, "json_object");
  assert.equal(firstBody.temperature, 0.25);
  assert.equal(firstBody.messages[1].role, "user");
  assert.match(firstBody.messages[1].content, /Asia\/Shanghai/);
  assert.match(firstBody.messages[1].content, /2026-06-08T17:15:00\.000\+08:00/);
  assert.match(firstBody.messages[1].content, /Input style: natural_language/);
  assert.equal(
    (calls[0]?.headers as Record<string, string>).Authorization,
    "Bearer test-key",
  );
});

test("allows parser temperature to be configured for real-input trials", async () => {
  const calls: RequestInit[] = [];
  const fetchFn = async (_url: string | URL | Request, init?: RequestInit) => {
    if (init) {
      calls.push(init);
    }
    return jsonCompletion(JSON.stringify(validParseResult));
  };
  const parser = createDeepSeekParser({
    apiKey: "test-key",
    fetchFn,
    temperature: 0.35,
  });

  await parser(parseRequest);

  const body = JSON.parse(String(calls[0]?.body));
  assert.equal(body.temperature, 0.35);
});

test("throws a timeout-specific error when DeepSeek does not respond within the timeout window", async () => {
  const fetchFn = (_url: string | URL | Request, init?: RequestInit) =>
    new Promise<Response>((_resolve, reject) => {
      if (init?.signal) {
        init.signal.addEventListener("abort", () =>
          reject(new DOMException("The operation was aborted", "AbortError")),
        );
      }
    });

  const parser = createDeepSeekParser({
    apiKey: "test-key",
    fetchFn,
    timeoutMs: 200,
  });

  const start = Date.now();
  await assert.rejects(
    () =>
      parser(parseRequest),
    (error) => {
      assert.equal(error instanceof ParserServiceError, true);
      assert.equal(
        (error as ParserServiceError).code,
        "deepseek_request_failed",
      );
      assert.equal((error as ParserServiceError).statusCode, 503);
      return true;
    },
  );
  const elapsed = Date.now() - start;
  assert.ok(
    elapsed < 5000,
    `timeout took ${elapsed}ms, expected < 5000ms`,
  );
});

test("throws a structured parse error after two invalid schema responses", async () => {
  let attempts = 0;
  const fetchFn = async () => {
    attempts += 1;
    return jsonCompletion(
      JSON.stringify({
        ...validParseResult,
        items: [{ ...validParseResult.items[0], type: "calendar_event" }],
      }),
    );
  };
  const parser = createDeepSeekParser({ apiKey: "test-key", fetchFn });

  await assert.rejects(
    () => parser(parseRequest),
    (error) => {
      assert.equal(error instanceof ParserServiceError, true);
      assert.equal((error as ParserServiceError).code, "invalid_parse_result");
      assert.equal((error as ParserServiceError).statusCode, 502);
      return true;
    },
  );
  assert.equal(attempts, 2);
});
