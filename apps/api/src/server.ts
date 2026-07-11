import cors from "cors";
import "dotenv/config";
import express, { type ErrorRequestHandler } from "express";
import { randomUUID } from "node:crypto";
import { pathToFileURL } from "node:url";

import {
  createParseRouter,
  type ParseText,
  type PrivacyLogger,
  type PrivacyLogEntry,
} from "./routes/parse.js";
import {
  createPlanRouter,
  type GeneratePlan,
} from "./routes/plan.js";
import { createAuthenticationMiddleware } from "./routes/authentication.js";
import {
  createReviewRouter,
  type GenerateReview,
} from "./routes/review.js";
import { createDeepSeekParser } from "./services/deepseekParser.js";
import { createDeepSeekPlan } from "./services/deepseekPlan.js";
import { createDeepSeekReview } from "./services/deepseekReview.js";
import {
  createEnvironmentCallerAuthenticator,
  type CallerAuthenticator,
} from "./services/callerAuthentication.js";
import {
  createEnvironmentDailyRequestQuota,
  type DailyRequestQuota,
} from "./services/dailyRequestQuota.js";
import {
  InMemoryRequestRateLimiter,
  type RequestRateLimiter,
} from "./services/requestRateLimiter.js";

export type { PrivacyLogEntry };

type CreateApiAppOptions = {
  parseText?: ParseText;
  generateReview?: GenerateReview;
  generatePlan?: GeneratePlan;
  logger?: PrivacyLogger;
  authenticator?: CallerAuthenticator;
  rateLimiter?: RequestRateLimiter;
  ipRateLimiter?: RequestRateLimiter;
  dailyRequestQuota?: DailyRequestQuota;
  now?: () => Date;
};

const defaultPrivacyLogger: PrivacyLogger = {
  error(entry) {
    console.error(JSON.stringify({ event: "parser_error", ...entry }));
  },
};

const handleUnhandledApiError: ErrorRequestHandler = (
  error: unknown,
  _request,
  response,
  _next,
) => {
  const status =
    typeof error === "object" && error != null && "status" in error
      ? (error as { status?: unknown }).status
      : undefined;
  const type =
    typeof error === "object" && error != null && "type" in error
      ? (error as { type?: unknown }).type
      : undefined;

  if (status === 413 || type === "entity.too.large") {
    response.status(413).json({
      error: {
        code: "request_too_large",
        message: "Request body exceeds the allowed size.",
      },
    });
    return;
  }

  if (status === 400 || error instanceof SyntaxError) {
    response.status(400).json({
      error: {
        code: "invalid_json",
        message: "Request body must be valid JSON.",
      },
    });
    return;
  }

  response.status(500).json({
    error: {
      code: "internal_error",
      message: "The API could not process this request.",
    },
  });
};

export function createApiApp(options: CreateApiAppOptions = {}) {
  const app = express();
  // Vercel forwards the client address through one trusted proxy. A self-hosted
  // deployment stays conservative by default and uses the socket address until
  // the operator explicitly configures its own trusted-proxy hop count.
  const trustedProxyHopsValue = process.env.TRUST_PROXY_HOPS?.trim();
  const configuredProxyHops =
    trustedProxyHopsValue != null && /^\d+$/.test(trustedProxyHopsValue)
      ? Number(trustedProxyHopsValue)
      : undefined;
  app.set(
    "trust proxy",
    configuredProxyHops != null
      ? configuredProxyHops
      : process.env.VERCEL === "1",
  );
  const logger = options.logger ?? defaultPrivacyLogger;
  const parseText = options.parseText ?? createDeepSeekParser();
  const generateReview = options.generateReview ?? createDeepSeekReview();
  const generatePlan = options.generatePlan ?? createDeepSeekPlan();
  const authenticator =
    options.authenticator ?? createEnvironmentCallerAuthenticator();
  const rateLimiter =
    options.rateLimiter ??
    new InMemoryRequestRateLimiter({ limit: 20, windowMs: 60_000 });
  const ipRateLimiter =
    options.ipRateLimiter ??
    new InMemoryRequestRateLimiter({ limit: 60, windowMs: 60_000 });
  const dailyRequestQuota =
    options.dailyRequestQuota ?? createEnvironmentDailyRequestQuota();

  app.disable("x-powered-by");
  app.use(cors({ origin: false }));
  app.use((_request, response, next) => {
    response.set({
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
    });
    next();
  });
  app.use(express.json({ limit: "128kb" }));

  app.get("/health", (_request, response) => {
    response.json({ ok: true });
  });

  app.use(
    createAuthenticationMiddleware({
      authenticator,
      rateLimiter,
      ipRateLimiter,
      dailyRequestQuota,
      ...(options.now == null ? {} : { now: options.now }),
    }),
  );

  app.use(
    createParseRouter(parseText, {
      logger,
      requestIdFactory: randomUUID,
    }),
  );
  app.use(
    createReviewRouter(generateReview, {
      logger,
      requestIdFactory: randomUUID,
    }),
  );
  app.use(
    createPlanRouter(generatePlan, {
      logger,
      requestIdFactory: randomUUID,
    }),
  );

  app.use(handleUnhandledApiError);

  return app;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.API_PORT ?? 8787);
  const app = createApiApp();

  app.listen(port, () => {
    console.log(`API proxy listening on port ${port}`);
  });
}
