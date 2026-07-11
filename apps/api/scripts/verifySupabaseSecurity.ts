import { randomUUID } from "node:crypto";

type TestUser = {
  id: string;
  token: string;
};

type QuotaDecision = {
  allowed: boolean;
  remaining: number;
};

const supabaseUrl = requiredEnvironment("SUPABASE_URL").replace(/\/+$/, "");
const publishableKey = requiredEnvironment("SUPABASE_PUBLISHABLE_KEY");
const userAToken = requiredEnvironment("SUPABASE_TEST_USER_A_TOKEN");
const userBToken = requiredEnvironment("SUPABASE_TEST_USER_B_TOKEN");

const userA = await loadUser(userAToken);
const userB = await loadUser(userBToken);
if (userA.id === userB.id) {
  throw new Error("The RLS verification requires two different test users.");
}

const runId = randomUUID();
const rawAId = `security-a-${runId}`;
const rawBId = `security-b-${runId}`;
const ownParseId = `security-own-${runId}`;
const crossParseId = `security-cross-${runId}`;

try {
  await insertRawInput(userA, rawAId, "security-test-a");
  await insertRawInput(userB, rawBId, "security-test-b");

  const bRowsVisibleToA = await selectRawInput(userA, rawBId);
  assert(bRowsVisibleToA.length === 0, "User A could read User B's row.");

  await updateRawInput(userA, rawBId, "tampered-by-a");
  await deleteRawInput(userA, rawBId);
  const bRowsVisibleToB = await selectRawInput(userB, rawBId);
  assert(
    bRowsVisibleToB.length === 1 &&
      bRowsVisibleToB[0]?.text === "security-test-b",
    "User A could update or delete User B's row.",
  );

  const ownReferenceResponse = await insertParseResult(
    userA,
    ownParseId,
    rawAId,
  );
  await assertOk(
    ownReferenceResponse,
    "Same-user source-reference control insert failed.",
  );

  const crossReferenceResponse = await insertParseResult(
    userA,
    crossParseId,
    rawBId,
  );
  const crossReferenceError = (await crossReferenceResponse.json()) as {
    code?: unknown;
  };
  assert(
    !crossReferenceResponse.ok && crossReferenceError.code === "23514",
    "Cross-user source reference was not rejected by the ownership guard.",
  );

  await deleteRawInput(userA, rawAId);
  assert(
    (await selectRawInput(userA, rawAId)).length === 0,
    "User A could not delete their own cloud copy.",
  );

  await verifyDurableQuota(userB);
  await deleteAccount(userB);

  const deletedUserResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: authHeaders(userB.token),
    signal: AbortSignal.timeout(5_000),
  });
  assert(
    deletedUserResponse.status === 401 || deletedUserResponse.status === 403,
    "Deleted test account still has an active Supabase session.",
  );

  console.log("PASS: two-user RLS read/update/delete isolation");
  console.log("PASS: cross-user source reference rejection");
  console.log("PASS: owner cloud-copy deletion");
  console.log("PASS: durable daily quota exhaustion");
  console.log("PASS: self-service account deletion and session invalidation");
} finally {
  await deleteRawInput(userA, rawAId).catch(() => undefined);
  await deleteRawInput(userB, rawBId).catch(() => undefined);
}

async function loadUser(token: string): Promise<TestUser> {
  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: authHeaders(token),
    signal: AbortSignal.timeout(5_000),
  });
  const body = await responseJson<{ id?: unknown }>(response);
  if (!response.ok || typeof body.id !== "string" || body.id.length === 0) {
    throw new Error("A supplied Supabase test token is invalid or expired.");
  }
  return { id: body.id, token };
}

async function insertRawInput(
  user: TestUser,
  id: string,
  text: string,
): Promise<void> {
  const response = await request("/rest/v1/raw_inputs", user, {
    method: "POST",
    headers: { Prefer: "return=minimal" },
    body: JSON.stringify({
      id,
      user_id: user.id,
      text,
      source: "security-test",
      created_at: new Date().toISOString(),
    }),
  });
  await assertOk(response, "Could not insert a disposable raw input.");
}

async function selectRawInput(
  user: TestUser,
  id: string,
): Promise<Array<{ id: string; text: string }>> {
  const response = await request(
    `/rest/v1/raw_inputs?id=eq.${encodeURIComponent(id)}&select=id,text`,
    user,
  );
  return responseJson<Array<{ id: string; text: string }>>(response);
}

function insertParseResult(
  user: TestUser,
  id: string,
  rawInputId: string,
): Promise<Response> {
  return request("/rest/v1/ai_parse_results", user, {
    method: "POST",
    headers: { Prefer: "return=minimal" },
    body: JSON.stringify({
      id,
      user_id: user.id,
      raw_input_id: rawInputId,
      raw_json: {},
      validation_state: "valid",
      retry_count: 0,
      created_at: new Date().toISOString(),
    }),
  });
}

async function updateRawInput(
  user: TestUser,
  id: string,
  text: string,
): Promise<void> {
  const response = await request(
    `/rest/v1/raw_inputs?id=eq.${encodeURIComponent(id)}`,
    user,
    {
      method: "PATCH",
      headers: { Prefer: "return=minimal" },
      body: JSON.stringify({ text }),
    },
  );
  await assertOk(response, "RLS update probe returned an unexpected error.");
}

async function deleteRawInput(user: TestUser, id: string): Promise<void> {
  const response = await request(
    `/rest/v1/raw_inputs?id=eq.${encodeURIComponent(id)}`,
    user,
    { method: "DELETE", headers: { Prefer: "return=minimal" } },
  );
  await assertOk(response, "Cloud-copy deletion returned an error.");
}

async function verifyDurableQuota(user: TestUser): Promise<void> {
  const first = await consumeQuota(user);
  assert(first.allowed, "Disposable quota user is already exhausted.");

  let decision = first;
  for (let attempt = 0; attempt <= first.remaining; attempt += 1) {
    decision = await consumeQuota(user);
  }
  assert(!decision.allowed, "Daily quota did not reject the request at zero.");
  assert(decision.remaining === 0, "Exhausted quota did not return zero.");
}

async function consumeQuota(user: TestUser): Promise<QuotaDecision> {
  const response = await request(
    "/rest/v1/rpc/consume_ai_daily_request_quota",
    user,
    { method: "POST", body: "{}" },
  );
  const rows = await responseJson<QuotaDecision[]>(response);
  const decision = rows[0];
  if (
    !response.ok ||
    !decision ||
    typeof decision.allowed !== "boolean" ||
    typeof decision.remaining !== "number"
  ) {
    throw new Error("Daily quota RPC returned an invalid decision.");
  }
  return decision;
}

async function deleteAccount(user: TestUser): Promise<void> {
  const response = await request("/rest/v1/rpc/delete_my_account", user, {
    method: "POST",
    body: "{}",
  });
  await assertOk(response, "Self-service account deletion failed.");
}

function request(
  path: string,
  user: TestUser,
  init: RequestInit = {},
): Promise<Response> {
  return fetch(`${supabaseUrl}${path}`, {
    ...init,
    headers: { ...authHeaders(user.token), ...init.headers },
    signal: AbortSignal.timeout(8_000),
  });
}

function authHeaders(token: string): Record<string, string> {
  return {
    apikey: publishableKey,
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };
}

async function assertOk(response: Response, message: string): Promise<void> {
  if (response.ok) return;
  const detail = (await response.text()).slice(0, 500);
  throw new Error(`${message} HTTP ${response.status}: ${detail}`);
}

async function responseJson<T>(response: Response): Promise<T> {
  if (!response.ok) {
    await assertOk(response, "Supabase request failed.");
  }
  return (await response.json()) as T;
}

function requiredEnvironment(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function assert(condition: boolean, message: string): asserts condition {
  if (!condition) throw new Error(message);
}
