import { Router } from "express";

import {
  parseRequestSchema,
  parseResultSchema,
  type ParseRequest,
  type ParseResult,
} from "../schemas/parseResultSchema.js";
import { ParserServiceError } from "../services/deepseekParser.js";

export type ParseText = (request: ParseRequest) => Promise<unknown>;

export type PrivacyLogEntry = {
  requestId: string;
  errorType: string;
  statusCode: number;
};

export type PrivacyLogger = {
  error: (entry: PrivacyLogEntry) => void;
};

type ParseRouterOptions = {
  logger?: PrivacyLogger;
  requestIdFactory?: () => string;
};

export function createParseRouter(
  parseText: ParseText,
  options: ParseRouterOptions = {},
): Router {
  const router = Router();

  router.post("/parse", async (request, response) => {
    const requestId =
      request.header("x-request-id") ?? options.requestIdFactory?.() ?? "unknown";
    const requestResult = parseRequestSchema.safeParse(request.body);

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
      const rawParseResult = await parseText(requestResult.data);
      const parseResult = parseResultSchema.safeParse(rawParseResult);

      if (!parseResult.success) {
        response.status(502).json({
          error: {
            code: "invalid_parse_result",
            issues: parseResult.error.issues,
          },
        });
        return;
      }

      response.json(parseResult.data satisfies ParseResult);
    } catch (error) {
      if (error instanceof ParserServiceError) {
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
        errorType: "parser_unavailable",
        statusCode: 503,
      });
      response.status(503).json({
        error: {
          code: "parser_unavailable",
          message: "Parser service is unavailable.",
          request_id: requestId,
        },
      });
    }
  });

  return router;
}
