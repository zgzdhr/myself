import type { NextFunction, Request, Response } from "express";

import {
  CallerAuthenticationError,
  type AuthenticatedCaller,
  type CallerAuthenticator,
} from "../services/callerAuthentication.js";
import {
  DailyRequestQuotaError,
  type DailyRequestQuota,
} from "../services/dailyRequestQuota.js";
import type { RequestRateLimiter } from "../services/requestRateLimiter.js";

type AuthenticationMiddlewareOptions = {
  authenticator: CallerAuthenticator;
  rateLimiter: RequestRateLimiter;
  ipRateLimiter: RequestRateLimiter;
  dailyRequestQuota: DailyRequestQuota;
  now?: () => Date;
};

function accessTokenFrom(request: Request): string | null {
  const authorization = request.header("authorization");
  if (!authorization) return null;

  const match = /^Bearer\s+(.+)$/i.exec(authorization.trim());
  return match?.[1]?.trim() || null;
}

function unauthorized(response: Response) {
  response.status(401).json({
    error: {
      code: "authentication_required",
      message: "A valid signed-in user session is required.",
    },
  });
}

function clientIp(request: Request): string {
  // Express applies the configured trusted-proxy policy before exposing `ip`.
  // Do not read x-forwarded-for directly here: doing so would let a direct
  // caller forge its bucket when the API is not behind the configured proxy.
  return request.ip || request.socket.remoteAddress || "unknown";
}

export function createAuthenticationMiddleware({
  authenticator,
  rateLimiter,
  ipRateLimiter,
  dailyRequestQuota,
  now = () => new Date(),
}: AuthenticationMiddlewareOptions) {
  return async (
    request: Request,
    response: Response,
    next: NextFunction,
  ): Promise<void> => {
    const ipDecision = ipRateLimiter.check(`ip:${clientIp(request)}`, now());
    if (!ipDecision.allowed) {
      response.set("Retry-After", String(ipDecision.retryAfterSeconds));
      response.status(429).json({
        error: {
          code: "rate_limited",
          message: "Too many requests. Please retry shortly.",
        },
      });
      return;
    }

    const accessToken = accessTokenFrom(request);
    if (!accessToken) {
      unauthorized(response);
      return;
    }

    let caller: AuthenticatedCaller;
    try {
      caller = await authenticator.authenticate(accessToken);
    } catch (error) {
      if (
        error instanceof CallerAuthenticationError &&
        error.code === "invalid_access_token"
      ) {
        unauthorized(response);
        return;
      }

      response.status(503).json({
        error: {
          code: "authentication_unavailable",
          message: "Authentication is temporarily unavailable.",
        },
      });
      return;
    }

    const decision = rateLimiter.check(caller.userId, now());
    if (!decision.allowed) {
      response.set("Retry-After", String(decision.retryAfterSeconds));
      response.status(429).json({
        error: {
          code: "rate_limited",
          message: "Too many AI requests. Please retry shortly.",
        },
      });
      return;
    }

    try {
      const dailyDecision = await dailyRequestQuota.consume(accessToken);
      if (!dailyDecision.allowed) {
        response.status(429).json({
          error: {
            code: "daily_quota_exhausted",
            message: "Daily AI request quota has been reached.",
          },
        });
        return;
      }
    } catch (error) {
      // A missing or failed shared quota must not silently turn this into an
      // unmetered paid-AI endpoint.
      if (error instanceof DailyRequestQuotaError) {
        response.status(503).json({
          error: {
            code: "quota_unavailable",
            message: "AI quota is temporarily unavailable.",
          },
        });
        return;
      }
      response.status(503).json({
        error: {
          code: "quota_unavailable",
          message: "AI quota is temporarily unavailable.",
        },
      });
      return;
    }

    response.locals.caller = caller;
    next();
  };
}
