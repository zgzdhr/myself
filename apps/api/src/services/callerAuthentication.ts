export type AuthenticatedCaller = {
  userId: string;
  email?: string;
};

export interface CallerAuthenticator {
  authenticate(accessToken: string): Promise<AuthenticatedCaller>;
}

export class CallerAuthenticationError extends Error {
  constructor(
    readonly code: "invalid_access_token" | "authentication_unavailable",
    message: string,
  ) {
    super(message);
    this.name = "CallerAuthenticationError";
  }
}

type SupabaseUserResponse = {
  id?: unknown;
  email?: unknown;
};

type CreateSupabaseCallerAuthenticatorOptions = {
  supabaseUrl: string;
  publishableKey: string;
  fetchImpl?: typeof fetch;
};

/**
 * Verifies the short-lived Supabase user token with Supabase Auth. The mobile
 * client only ever receives the publishable key; no service-role credential is
 * used by this verifier.
 */
export function createSupabaseCallerAuthenticator({
  supabaseUrl,
  publishableKey,
  fetchImpl = fetch,
}: CreateSupabaseCallerAuthenticatorOptions): CallerAuthenticator {
  const authUserUrl = new URL("/auth/v1/user", supabaseUrl).toString();

  return {
    async authenticate(accessToken) {
      let response: Response;
      try {
        response = await fetchImpl(authUserUrl, {
          headers: {
            apikey: publishableKey,
            Authorization: `Bearer ${accessToken}`,
          },
        });
      } catch {
        throw new CallerAuthenticationError(
          "authentication_unavailable",
          "Unable to verify the caller with Supabase Auth.",
        );
      }

      if (response.status === 401 || response.status === 403) {
        throw new CallerAuthenticationError(
          "invalid_access_token",
          "The supplied access token is invalid or expired.",
        );
      }

      if (!response.ok) {
        throw new CallerAuthenticationError(
          "authentication_unavailable",
          "Supabase Auth returned an unsuccessful response.",
        );
      }

      let body: SupabaseUserResponse;
      try {
        body = (await response.json()) as SupabaseUserResponse;
      } catch {
        throw new CallerAuthenticationError(
          "authentication_unavailable",
          "Supabase Auth returned an invalid response.",
        );
      }

      if (typeof body.id !== "string" || body.id.length === 0) {
        throw new CallerAuthenticationError(
          "authentication_unavailable",
          "Supabase Auth did not return a user id.",
        );
      }

      return {
        userId: body.id,
        ...(typeof body.email === "string" ? { email: body.email } : {}),
      };
    },
  };
}

export function createEnvironmentCallerAuthenticator(
  environment: NodeJS.ProcessEnv = process.env,
): CallerAuthenticator {
  const supabaseUrl = environment.SUPABASE_URL?.trim();
  const publishableKey = environment.SUPABASE_PUBLISHABLE_KEY?.trim();

  if (!supabaseUrl || !publishableKey) {
    return {
      async authenticate() {
        throw new CallerAuthenticationError(
          "authentication_unavailable",
          "The API is missing Supabase authentication configuration.",
        );
      },
    };
  }

  return createSupabaseCallerAuthenticator({ supabaseUrl, publishableKey });
}
