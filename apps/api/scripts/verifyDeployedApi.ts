const apiBaseUrl = requiredEnvironment("API_BASE_URL").replace(/\/+$/, "");
const accessToken = requiredEnvironment("SUPABASE_TEST_USER_A_TOKEN");
const currentTime = new Date();
const planDate = dateInTimezone(currentTime, "Asia/Shanghai");

const health = await fetch(`${apiBaseUrl}/health`, {
  signal: AbortSignal.timeout(8_000),
});
assert(health.status === 200, "Public health endpoint is not ready.");
assert(health.headers.get("x-powered-by") == null, "Framework header leaked.");
assert(health.headers.get("cache-control") === "no-store", "Missing no-store.");

const anonymous = await post("/parse", parseRequest(), undefined);
assert(anonymous.status === 401, "Anonymous AI request was not rejected.");

const invalidToken = await post("/parse", parseRequest(), "invalid-test-token");
assert(invalidToken.status === 401, "Invalid AI token was not rejected.");

const parse = await post("/parse", parseRequest(), accessToken);
await assertSuccessJson(parse, "Authenticated /parse failed.");

const review = await post(
  "/review",
  {
    timezone: "Asia/Shanghai",
    review_date: planDate,
    current_time_iso: currentTime.toISOString(),
    user_note: "这是无隐私内容的部署验证。",
    tasks: [],
    short_term_states: [],
    life_events: [],
    profile_items: [],
  },
  accessToken,
);
await assertSuccessJson(review, "Authenticated /review failed.");

const plan = await post(
  "/plan",
  {
    timezone: "Asia/Shanghai",
    plan_date: planDate,
    current_time_iso: currentTime.toISOString(),
    user_note: "这是无隐私内容的部署验证。",
    day_start_hour: 8,
    day_end_hour: 22,
    tasks: [
      {
        id: "deployment-test-task",
        title: "完成部署验证",
        due_time_iso: `${planDate}T18:00:00+08:00`,
        task_status: "active",
        status: "confirmed",
      },
    ],
    short_term_states: [],
    profile_items: [],
    recent_summaries: [],
  },
  accessToken,
);
await assertSuccessJson(plan, "Authenticated /plan failed.");

// Three successful AI calls above already count toward the 20/minute user
// burst. Invalid route bodies still pass auth/quota but stop before DeepSeek,
// so these probes verify rate limiting without paying for 17 extra model calls.
for (let attempt = 0; attempt < 17; attempt += 1) {
  const invalidRequest = await post("/parse", { text: "" }, accessToken);
  assert(
    invalidRequest.status === 400,
    "An invalid authenticated probe did not stop at request validation.",
  );
}

const limited = await post("/parse", { text: "" }, accessToken);
assert(limited.status === 429, "The 21st user request was not rate limited.");
const limitedBody = (await limited.json()) as { error?: { code?: unknown } };
assert(limitedBody.error?.code === "rate_limited", "Unexpected limit error.");

console.log("PASS: public health endpoint and security headers");
console.log("PASS: anonymous and invalid-token rejection");
console.log("PASS: authenticated /parse, /review, and /plan");
console.log("PASS: deployed per-user burst limit without extra model calls");

function parseRequest(): Record<string, unknown> {
  return {
    text: "请回答一加一等于多少，不保存任何内容。",
    timezone: "Asia/Shanghai",
    current_time_iso: currentTime.toISOString(),
    input_style: "natural_language",
  };
}

function post(
  path: string,
  body: unknown,
  token: string | undefined,
): Promise<Response> {
  return fetch(`${apiBaseUrl}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(token == null ? {} : { Authorization: `Bearer ${token}` }),
    },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(30_000),
  });
}

async function assertSuccessJson(
  response: Response,
  message: string,
): Promise<void> {
  if (!response.ok) {
    const detail = (await response.text()).slice(0, 500);
    throw new Error(`${message} HTTP ${response.status}: ${detail}`);
  }
  const contentType = response.headers.get("content-type") ?? "";
  assert(contentType.includes("application/json"), `${message} Not JSON.`);
  await response.json();
}

function dateInTimezone(date: Date, timezone: string): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}

function requiredEnvironment(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function assert(condition: boolean, message: string): asserts condition {
  if (!condition) throw new Error(message);
}
