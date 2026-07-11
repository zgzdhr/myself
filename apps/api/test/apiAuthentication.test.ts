import assert from "node:assert/strict";
import { once } from "node:events";
import type { Server } from "node:http";
import test from "node:test";

import { createApiApp } from "../src/server.js";
import type { CallerAuthenticator } from "../src/services/callerAuthentication.js";
import type { DailyRequestQuota } from "../src/services/dailyRequestQuota.js";
import { InMemoryRequestRateLimiter } from "../src/services/requestRateLimiter.js";

const parseRequest = {
  text: "明天上午联系王总",
  timezone: "Asia/Shanghai",
  current_time_iso: "2026-07-10T09:00:00.000+08:00",
};

const parseResponse = {
  user_reply: "已整理。",
  input_summary: "明天联系王总。",
  intent_types: [],
  items: [],
  memory_candidates: [],
  safety_flags: [],
  need_follow_up_question: false,
  follow_up_question: null,
};

const validAuthenticator: CallerAuthenticator = {
  async authenticate(token) {
    if (token !== "valid-session-token") {
      throw new Error("unexpected test token");
    }
    return { userId: "user-1", email: "user@example.com" };
  },
};

test("AI routes reject requests without a signed-in user session", async () => {
  let parserCalled = false;
  const { server, baseUrl } = await startApp({
    parseText: async () => {
      parserCalled = true;
      return parseResponse;
    },
  });

  try {
    const response = await fetch(`${baseUrl}/parse`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(parseRequest),
    });

    assert.equal(response.status, 401);
    assert.deepEqual(await response.json(), {
      error: {
        code: "authentication_required",
        message: "A valid signed-in user session is required.",
      },
    });
    assert.equal(parserCalled, false);
  } finally {
    await closeServer(server);
  }
});

test("public health response exposes no framework or cacheable metadata", async () => {
  const { server, baseUrl } = await startApp({
    parseText: async () => parseResponse,
  });

  try {
    const response = await fetch(`${baseUrl}/health`);

    assert.equal(response.status, 200);
    assert.equal(response.headers.get("x-powered-by"), null);
    assert.equal(response.headers.get("cache-control"), "no-store");
    assert.equal(response.headers.get("referrer-policy"), "no-referrer");
    assert.equal(response.headers.get("x-content-type-options"), "nosniff");
    assert.equal(response.headers.get("access-control-allow-origin"), null);
  } finally {
    await closeServer(server);
  }
});

test("API rejects malformed JSON with a stable safe error", async () => {
  const { server, baseUrl } = await startApp({
    parseText: async () => parseResponse,
  });

  try {
    const response = await fetch(`${baseUrl}/parse`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: "{not-json",
    });

    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), {
      error: {
        code: "invalid_json",
        message: "Request body must be valid JSON.",
      },
    });
  } finally {
    await closeServer(server);
  }
});

test("API rejects bodies over 128kb before authentication or AI use", async () => {
  const { server, baseUrl } = await startApp({
    parseText: async () => parseResponse,
  });

  try {
    const response = await fetch(`${baseUrl}/parse`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: "x".repeat(140_000) }),
    });

    assert.equal(response.status, 413);
    assert.equal((await response.json()).error.code, "request_too_large");
  } finally {
    await closeServer(server);
  }
});

test("AI routes accept a verified Supabase session token", async () => {
  const { server, baseUrl } = await startApp({
    parseText: async () => parseResponse,
  });

  try {
    const response = await fetch(`${baseUrl}/parse`, {
      method: "POST",
      headers: {
        Authorization: "Bearer valid-session-token",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(parseRequest),
    });

    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), parseResponse);
  } finally {
    await closeServer(server);
  }
});

test("AI routes apply a per-user burst limit", async () => {
  const { server, baseUrl } = await startApp({
    parseText: async () => parseResponse,
    rateLimiter: new InMemoryRequestRateLimiter({
      limit: 1,
      windowMs: 60_000,
    }),
  });

  try {
    const request = () =>
      fetch(`${baseUrl}/parse`, {
        method: "POST",
        headers: {
          Authorization: "Bearer valid-session-token",
          "Content-Type": "application/json",
        },
        body: JSON.stringify(parseRequest),
      });

    assert.equal((await request()).status, 200);
    const limited = await request();
    assert.equal(limited.status, 429);
    assert.equal(limited.headers.get("retry-after"), "60");
    assert.equal((await limited.json()).error.code, "rate_limited");
  } finally {
    await closeServer(server);
  }
});

test("AI routes apply a pre-authentication IP burst limit", async () => {
  const { server, baseUrl } = await startApp({
    parseText: async () => parseResponse,
    ipRateLimiter: new InMemoryRequestRateLimiter({
      limit: 1,
      windowMs: 60_000,
    }),
  });

  try {
    const request = () =>
      fetch(`${baseUrl}/parse`, {
        method: "POST",
        headers: {
          Authorization: "Bearer valid-session-token",
          "Content-Type": "application/json",
        },
        body: JSON.stringify(parseRequest),
      });

    assert.equal((await request()).status, 200);
    const limited = await request();
    assert.equal(limited.status, 429);
    assert.equal((await limited.json()).error.code, "rate_limited");
  } finally {
    await closeServer(server);
  }
});

test("AI routes reject callers after their daily quota is exhausted", async () => {
  const { server, baseUrl } = await startApp({
    parseText: async () => parseResponse,
    dailyRequestQuota: { async consume() { return { allowed: false, remaining: 0 }; } },
  });

  try {
    const response = await fetch(`${baseUrl}/parse`, {
      method: "POST",
      headers: {
        Authorization: "Bearer valid-session-token",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(parseRequest),
    });

    assert.equal(response.status, 429);
    assert.equal((await response.json()).error.code, "daily_quota_exhausted");
  } finally {
    await closeServer(server);
  }
});

async function startApp(options: {
  parseText: () => Promise<unknown>;
  rateLimiter?: InMemoryRequestRateLimiter;
  ipRateLimiter?: InMemoryRequestRateLimiter;
  dailyRequestQuota?: DailyRequestQuota;
}): Promise<{ server: Server; baseUrl: string }> {
  const app = createApiApp({
    parseText: options.parseText,
    authenticator: validAuthenticator,
    dailyRequestQuota: options.dailyRequestQuota ?? allowAllDailyQuota,
    ...(options.rateLimiter == null ? {} : { rateLimiter: options.rateLimiter }),
    ...(options.ipRateLimiter == null
      ? {}
      : { ipRateLimiter: options.ipRateLimiter }),
  });
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");
  const address = server.address();

  if (address == null || typeof address === "string") {
    throw new Error("Expected server to listen on a TCP port.");
  }

  return { server, baseUrl: `http://127.0.0.1:${address.port}` };
}

const allowAllDailyQuota: DailyRequestQuota = {
  async consume() {
    return { allowed: true, remaining: 29 };
  },
};

async function closeServer(server: Server): Promise<void> {
  server.closeIdleConnections();
  server.closeAllConnections();
  await new Promise<void>((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
}
