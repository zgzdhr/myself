import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import type { Server } from "node:http";

import { createApiApp, type PrivacyLogEntry } from "../src/server.js";
import { ParserServiceError } from "../src/services/deepseekParser.js";

const sensitiveText = "明天联系王总，我今天很累，我不喜欢太频繁的提醒。";

let server: Server;
let baseUrl: string;

before(async () => {
  const logs: PrivacyLogEntry[] = [];
  const app = createApiApp({
    parseText: async () => {
      throw new ParserServiceError(
        "deepseek_http_error",
        503,
        "DeepSeek API returned an unsuccessful response.",
      );
    },
    logger: {
      error(entry) {
        logs.push(entry);
      },
    },
  });

  server = app.listen(0);
  await new Promise<void>((resolve) => server.once("listening", resolve));
  const address = server.address();

  if (address == null || typeof address === "string") {
    throw new Error("Expected server to listen on a TCP port.");
  }

  baseUrl = `http://127.0.0.1:${address.port}`;
  globalThis.__privacyLogs = logs;
});

after(async () => {
  await new Promise<void>((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
});

test("logs parser errors with request id and error type but without raw user text", async () => {
  const response = await fetch(`${baseUrl}/parse`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-request-id": "privacy-test-request",
    },
    body: JSON.stringify({
      text: sensitiveText,
      timezone: "Asia/Shanghai",
      current_time_iso: "2026-06-08T17:15:00.000+08:00",
    }),
  });

  const logs = globalThis.__privacyLogs;
  const body = await response.json();

  assert.equal(response.status, 503);
  assert.equal(logs.length, 1);
  assert.equal(logs[0]?.requestId, "privacy-test-request");
  assert.equal(logs[0]?.errorType, "deepseek_http_error");
  assert.equal(body.error.request_id, "privacy-test-request");
  assert.doesNotMatch(JSON.stringify(logs), /王总|很累|频繁的提醒/);
});

declare global {
  // eslint-disable-next-line no-var
  var __privacyLogs: PrivacyLogEntry[];
}
