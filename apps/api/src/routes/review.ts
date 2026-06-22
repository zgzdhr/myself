import { Router } from "express";

import {
  reviewRequestSchema,
  reviewResultSchema,
  type ReviewRequest,
  type ReviewResult,
} from "../schemas/reviewResultSchema.js";
import { ReviewServiceError } from "../services/deepseekReview.js";

export type GenerateReview = (request: ReviewRequest) => Promise<unknown>;

export type ReviewPrivacyLogEntry = {
  requestId: string;
  errorType: string;
  statusCode: number;
};

export type ReviewPrivacyLogger = {
  error: (entry: ReviewPrivacyLogEntry) => void;
};

type ReviewRouterOptions = {
  logger?: ReviewPrivacyLogger;
  requestIdFactory?: () => string;
};

export function createReviewRouter(
  generateReview: GenerateReview,
  options: ReviewRouterOptions = {},
): Router {
  const router = Router();

  router.post("/review", async (request, response) => {
    const requestId =
      request.header("x-request-id") ?? options.requestIdFactory?.() ?? "unknown";
    const requestResult = reviewRequestSchema.safeParse(request.body);

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
      const rawReviewResult = await generateReview(requestResult.data);
      const reviewResult = reviewResultSchema.safeParse(rawReviewResult);

      if (!reviewResult.success) {
        response.status(502).json({
          error: {
            code: "invalid_review_result",
            issues: reviewResult.error.issues,
          },
        });
        return;
      }

      response.json(reviewResult.data satisfies ReviewResult);
    } catch (error) {
      if (error instanceof ReviewServiceError) {
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
        errorType: "review_unavailable",
        statusCode: 503,
      });
      response.status(503).json({
        error: {
          code: "review_unavailable",
          message: "Review service is unavailable.",
          request_id: requestId,
        },
      });
    }
  });

  return router;
}
