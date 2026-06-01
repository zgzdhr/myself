import assert from "node:assert/strict";
import test from "node:test";

import {
  createDeepSeekParser,
  ParserServiceError,
} from "../src/services/deepseekParser.js";

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
    () => parser({ text: "明天联系王总", timezone: "Asia/Shanghai" }),
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
    () => parser({ text: "明天联系王总", timezone: "Asia/Shanghai" }),
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

  const result = await parser({
    text: "明天联系王总",
    timezone: "Asia/Shanghai",
  });

  assert.equal(calls.length, 2);
  assert.equal(result.items[0]?.type, "task_create");

  const firstBody = JSON.parse(String(calls[0]?.body));
  assert.equal(firstBody.response_format.type, "json_object");
  assert.equal(firstBody.messages[1].role, "user");
  assert.match(firstBody.messages[1].content, /Asia\/Shanghai/);
  assert.equal(
    (calls[0]?.headers as Record<string, string>).Authorization,
    "Bearer test-key",
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
    () => parser({ text: "明天联系王总", timezone: "Asia/Shanghai" }),
    (error) => {
      assert.equal(error instanceof ParserServiceError, true);
      assert.equal((error as ParserServiceError).code, "invalid_parse_result");
      assert.equal((error as ParserServiceError).statusCode, 502);
      return true;
    },
  );
  assert.equal(attempts, 2);
});
