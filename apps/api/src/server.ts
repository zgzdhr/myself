import cors from "cors";
import "dotenv/config";
import express from "express";
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
import {
  createReviewRouter,
  type GenerateReview,
} from "./routes/review.js";
import { createDeepSeekParser } from "./services/deepseekParser.js";
import { createDeepSeekPlan } from "./services/deepseekPlan.js";
import { createDeepSeekReview } from "./services/deepseekReview.js";

export type { PrivacyLogEntry };

type CreateApiAppOptions = {
  parseText?: ParseText;
  generateReview?: GenerateReview;
  generatePlan?: GeneratePlan;
  logger?: PrivacyLogger;
};

const defaultPrivacyLogger: PrivacyLogger = {
  error(entry) {
    console.error(JSON.stringify({ event: "parser_error", ...entry }));
  },
};

export function createApiApp(options: CreateApiAppOptions = {}) {
  const app = express();
  const logger = options.logger ?? defaultPrivacyLogger;
  const parseText = options.parseText ?? createDeepSeekParser();
  const generateReview = options.generateReview ?? createDeepSeekReview();
  const generatePlan = options.generatePlan ?? createDeepSeekPlan();

  app.use(cors());
  app.use(express.json({ limit: "1mb" }));

  app.get("/health", (_request, response) => {
    response.json({ ok: true });
  });

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

  return app;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.API_PORT ?? 8787);
  const app = createApiApp();

  app.listen(port, () => {
    console.log(`API proxy listening on port ${port}`);
  });
}
