export type DailyQuotaDecision =
  | { allowed: true; remaining: number }
  | { allowed: false; remaining: 0 };

export interface DailyRequestQuota {
  consume(accessToken: string): Promise<DailyQuotaDecision>;
}

export class DailyRequestQuotaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "DailyRequestQuotaError";
  }
}

type SupabaseQuotaRow = {
  allowed?: unknown;
  remaining?: unknown;
};

type CreateSupabaseDailyRequestQuotaOptions = {
  supabaseUrl: string;
  publishableKey: string;
  fetchImpl?: typeof fetch;
};

/**
 * Consumes the private-trial daily AI quota through a Supabase RPC executed as
 * the caller's own JWT. The API does not need, receive, or log a service-role
 * key for this operation.
 */
export function createSupabaseDailyRequestQuota({
  supabaseUrl,
  publishableKey,
  fetchImpl = fetch,
}: CreateSupabaseDailyRequestQuotaOptions): DailyRequestQuota {
  const quotaUrl = new URL(
    "/rest/v1/rpc/consume_ai_daily_request_quota",
    supabaseUrl,
  ).toString();

  return {
    async consume(accessToken) {
      let response: Response;
      try {
        response = await fetchImpl(quotaUrl, {
          method: "POST",
          headers: {
            apikey: publishableKey,
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: "{}",
          signal: AbortSignal.timeout(3_000),
        });
      } catch {
        throw new DailyRequestQuotaError("Unable to consume daily AI quota.");
      }

      if (!response.ok) {
        throw new DailyRequestQuotaError(
          "Supabase daily AI quota returned an unsuccessful response.",
        );
      }

      let rows: SupabaseQuotaRow[];
      try {
        rows = (await response.json()) as SupabaseQuotaRow[];
      } catch {
        throw new DailyRequestQuotaError(
          "Supabase daily AI quota returned an invalid response.",
        );
      }

      const decision = rows[0];
      if (
        !decision ||
        typeof decision.allowed !== "boolean" ||
        typeof decision.remaining !== "number" ||
        !Number.isSafeInteger(decision.remaining) ||
        decision.remaining < 0
      ) {
        throw new DailyRequestQuotaError(
          "Supabase daily AI quota returned an invalid decision.",
        );
      }

      if (decision.allowed) {
        return { allowed: true, remaining: decision.remaining };
      }
      return { allowed: false, remaining: 0 };
    },
  };
}

export function createEnvironmentDailyRequestQuota(
  environment: NodeJS.ProcessEnv = process.env,
): DailyRequestQuota {
  const supabaseUrl = environment.SUPABASE_URL?.trim();
  const publishableKey = environment.SUPABASE_PUBLISHABLE_KEY?.trim();

  if (!supabaseUrl || !publishableKey) {
    return {
      async consume() {
        throw new DailyRequestQuotaError(
          "The API is missing Supabase daily-quota configuration.",
        );
      },
    };
  }

  return createSupabaseDailyRequestQuota({ supabaseUrl, publishableKey });
}
