import { pathToFileURL } from "node:url";

import {
  parseResultSchema,
  type ParseResult,
} from "../src/schemas/parseResultSchema.js";
import {
  parserSmokeSamples,
  type ParserItemType,
  type ParserSmokeSample,
} from "../src/services/parserSampleSet.js";

type FetchLike = (
  input: string | URL | Request,
  init?: RequestInit,
) => Promise<Response>;

export type SmokeSampleResult = {
  sampleId: string;
  label: string;
  ok: boolean;
  actualTypes: ParserItemType[];
  missingTypes: ParserItemType[];
  forbiddenTypes: ParserItemType[];
};

export type RunParseSmokeOptions = {
  baseUrl?: string;
  timezone?: string;
  samples?: ParserSmokeSample[];
  fetchFn?: FetchLike;
};

export function evaluateSampleResult(
  sample: ParserSmokeSample,
  result: ParseResult,
): SmokeSampleResult {
  const actualTypes = [...new Set(result.items.map((item) => item.type))];
  const missingTypes = sample.expectedTypes.filter(
    (type) => !actualTypes.includes(type),
  );
  const forbiddenTypes = (sample.forbiddenTypes ?? []).filter((type) =>
    actualTypes.includes(type),
  );

  return {
    sampleId: sample.id,
    label: sample.label,
    ok: missingTypes.length === 0 && forbiddenTypes.length === 0,
    actualTypes,
    missingTypes,
    forbiddenTypes,
  };
}

export async function runParseSmoke({
  baseUrl = process.env.API_BASE_URL ?? "http://127.0.0.1:8787",
  timezone = "Asia/Shanghai",
  samples = parserSmokeSamples,
  fetchFn = fetch,
}: RunParseSmokeOptions = {}): Promise<SmokeSampleResult[]> {
  const normalizedBaseUrl = baseUrl.replace(/\/+$/, "");

  const healthResponse = await fetchFn(`${normalizedBaseUrl}/health`);
  if (!healthResponse.ok) {
    throw new Error(`Health check failed with status ${healthResponse.status}`);
  }

  const results: SmokeSampleResult[] = [];

  for (const sample of samples) {
    const response = await fetchFn(`${normalizedBaseUrl}/parse`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        text: sample.text,
        timezone,
      }),
    });

    if (!response.ok) {
      throw new Error(
        `Parse request failed for ${sample.id} with status ${response.status}`,
      );
    }

    const payload = await response.json();
    const parsed = parseResultSchema.parse(payload);
    results.push(evaluateSampleResult(sample, parsed));
  }

  return results;
}

function printResults(results: SmokeSampleResult[]): void {
  for (const result of results) {
    const status = result.ok ? "PASS" : "FAIL";
    const actual = result.actualTypes.join(", ") || "none";
    console.log(`${status} ${result.sampleId} (${result.label}) -> ${actual}`);

    if (result.missingTypes.length > 0) {
      console.log(`  missing: ${result.missingTypes.join(", ")}`);
    }

    if (result.forbiddenTypes.length > 0) {
      console.log(`  forbidden: ${result.forbiddenTypes.join(", ")}`);
    }
  }
}

async function main(): Promise<void> {
  const results = await runParseSmoke();
  printResults(results);

  if (results.some((result) => !result.ok)) {
    process.exitCode = 1;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error: unknown) => {
    const message = error instanceof Error ? error.message : "Unknown smoke error";
    console.error(message);
    process.exitCode = 1;
  });
}
