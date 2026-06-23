import { Router } from "express";

import {
  planRequestSchema,
  planResultSchema,
  type PlanRequest,
  type PlanResult,
} from "../schemas/planResultSchema.js";
import { PlanServiceError } from "../services/deepseekPlan.js";

export type GeneratePlan = (request: PlanRequest) => Promise<unknown>;

export type PlanPrivacyLogEntry = {
  requestId: string;
  errorType: string;
  statusCode: number;
};

export type PlanPrivacyLogger = {
  error: (entry: PlanPrivacyLogEntry) => void;
};

type PlanRouterOptions = {
  logger?: PlanPrivacyLogger;
  requestIdFactory?: () => string;
};

export function createPlanRouter(
  generatePlan: GeneratePlan,
  options: PlanRouterOptions = {},
): Router {
  const router = Router();

  router.post("/plan", async (request, response) => {
    const requestId =
      request.header("x-request-id") ?? options.requestIdFactory?.() ?? "unknown";
    const requestResult = planRequestSchema.safeParse(request.body);

    if (!requestResult.success) {
      response.status(400).json({
        error: {
          code: "invalid_request",
          issues: requestResult.error.issues,
        },
      });
      return;
    }

    try {
      const rawPlanResult = await generatePlan(requestResult.data);
      const planResult = planResultSchema.safeParse(rawPlanResult);

      if (!planResult.success) {
        response.status(502).json({
          error: {
            code: "invalid_plan_result",
            issues: planResult.error.issues,
          },
        });
        return;
      }

      response.json(planResult.data satisfies PlanResult);
    } catch (error) {
      if (error instanceof PlanServiceError) {
        options.logger?.error(error.toLogEntry(requestId));
        response.status(error.statusCode).json({
          error: {
            code: error.code,
            message: error.message,
            details: error.details,
            request_id: requestId,
          },
        });
        return;
      }

      options.logger?.error({
        requestId,
        errorType: "plan_unavailable",
        statusCode: 503,
      });
      response.status(503).json({
        error: {
          code: "plan_unavailable",
          message: "Plan service is unavailable.",
          request_id: requestId,
        },
      });
    }
  });

  return router;
}
