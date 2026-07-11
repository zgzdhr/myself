import assert from "node:assert/strict";
import test from "node:test";

import {
  DailyRequestQuotaError,
  createEnvironmentDailyRequestQuota,
  createSupabaseDailyRequestQuota,
} from "../src/services/dailyRequestQuota.js";

test("daily quota RPC uses the caller token and returns its decision", async () => {
  let request: Request | undefined;
  const quota = createSupabaseDailyRequestQuota({
    supabaseUrl: "https://project-ref.supabase.co",
    publishableKey: "publishable-key",
    fetchImpl: async (input, init) => {
      request = new Request(input, init);
      return Response.json([{ allowed: true, remaining: 29 }]);
    },
  });

  assert.deepEqual(await quota.consume("caller-token"), {
    allowed: true,
    remaining: 29,
  });
  assert.equal(
    request?.url,
    "https://project-ref.supabase.co/rest/v1/rpc/consume_ai_daily_request_quota",
  );
  assert.equal(request?.headers.get("authorization"), "Bearer caller-token");
  assert.equal(request?.headers.get("apikey"), "publishable-key");
});

test("daily quota fails closed for malformed RPC responses", async () => {
  const quota = createSupabaseDailyRequestQuota({
    supabaseUrl: "https://project-ref.supabase.co",
    publishableKey: "publishable-key",
    fetchImpl: async () => Response.json([{ allowed: "yes", remaining: 29 }]),
  });

  await assert.rejects(
    quota.consume("caller-token"),
    DailyRequestQuotaError,
  );
});

test("daily quota fails closed when Supabase settings are absent", async () => {
  const quota = createEnvironmentDailyRequestQuota({});

  await assert.rejects(quota.consume("caller-token"), DailyRequestQuotaError);
});
