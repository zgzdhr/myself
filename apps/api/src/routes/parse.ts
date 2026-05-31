import { Router } from "express";

import {
  parseRequestSchema,
  parseResultSchema,
  type ParseRequest,
  type ParseResult,
} from "../schemas/parseResultSchema.js";

type ParseText = (request: ParseRequest) => Promise<unknown>;

export function createParseRouter(parseText: ParseText): Router {
  const router = Router();

  router.post("/parse", async (request, response) => {
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
    } catch {
      response.status(503).json({
        error: {
          code: "parser_unavailable",
          message: "Parser service is not configured yet.",
        },
      });
    }
  });

  return router;
}
