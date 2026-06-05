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
  ruleFailures: string[];
};

type SchemaErrorEntry = {
  sampleId: string;
  label: string;
  error: string;
};

const VAGUE_PHRASES = ["最近", "有空", "这两天", "这几天", "过几天", "找个时间"];
const SAVEABLE_TYPES: ParserItemType[] = [
  "task_create",
  "short_term_state",
  "life_event",
  "profile_candidate",
];

export function evaluateSampleResult(
  sample: ParserSmokeSample,
  result: ParseResult,
): SmokeSampleResult {
  const actualTypes = [...new Set(result.items.map((item) => item.type))];
  const missingTypes = sample.expectedTypes.filter((type) => {
    if (actualTypes.includes(type)) return false;
    return !sample.acceptedTypes?.some((acceptedType) =>
      actualTypes.includes(acceptedType),
    );
  });
  const forbiddenTypes = (sample.forbiddenTypes ?? []).filter((type) =>
    actualTypes.includes(type),
  );

  const ruleFailures: string[] = [];

  for (const item of result.items) {
    if (item.type === "profile_candidate" && item.need_user_confirm !== true) {
      ruleFailures.push(
        `profile_candidate "${item.title ?? item.content ?? "(untitled)"}" has need_user_confirm=${item.need_user_confirm}`,
      );
    }

    if (!item.source_text || item.source_text.trim().length === 0) {
      ruleFailures.push(
        `item of type ${item.type} has empty source_text`,
      );
    }

    if (item.confidence < 0 || item.confidence > 1) {
      ruleFailures.push(
        `item of type ${item.type} has confidence=${item.confidence}`,
      );
    }

    if (
      (sample.id.includes("vague") || sample.label.includes("模糊")) &&
      item.due_time_iso &&
      item.due_time_text &&
      VAGUE_PHRASES.some((p) => item.due_time_text!.includes(p))
    ) {
      ruleFailures.push(
        `vague time fabricated due_time_iso="${item.due_time_iso}" for text="${item.due_time_text}"`,
      );
    }
  }

  if (
    sample.expectedTypes.includes("general_answer") &&
    (sample.forbiddenTypes ?? []).some((t) => (SAVEABLE_TYPES as string[]).includes(t))
  ) {
    const producedSaveable = actualTypes.filter((t) =>
      (SAVEABLE_TYPES as string[]).includes(t),
    );
    if (producedSaveable.length > 0) {
      ruleFailures.push(
        `general_answer sample produced saveable types: ${producedSaveable.join(", ")}`,
      );
    }
  }

  return {
    sampleId: sample.id,
    label: sample.label,
    ok:
      missingTypes.length === 0 &&
      forbiddenTypes.length === 0 &&
      ruleFailures.length === 0,
    actualTypes,
    missingTypes,
    forbiddenTypes,
    ruleFailures,
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
    let response: Response;
    try {
      response = await fetchFn(`${normalizedBaseUrl}/parse`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text: sample.text, timezone }),
      });
    } catch {
      results.push({
        sampleId: sample.id,
        label: sample.label,
        ok: false,
        actualTypes: [],
        missingTypes: [],
        forbiddenTypes: [],
        ruleFailures: ["HTTP request failed"],
      });
      continue;
    }

    if (!response.ok) {
      results.push({
        sampleId: sample.id,
        label: sample.label,
        ok: false,
        actualTypes: [],
        missingTypes: [],
        forbiddenTypes: [],
        ruleFailures: [`HTTP ${response.status}`],
      });
      continue;
    }

    let payload: unknown;
    try {
      payload = await response.json();
    } catch {
      results.push({
        sampleId: sample.id,
        label: sample.label,
        ok: false,
        actualTypes: [],
        missingTypes: [],
        forbiddenTypes: [],
        ruleFailures: ["response is not valid JSON"],
      });
      continue;
    }

    const parsed = parseResultSchema.safeParse(payload);
    if (!parsed.success) {
      results.push({
        sampleId: sample.id,
        label: sample.label,
        ok: false,
        actualTypes: [],
        missingTypes: [],
        forbiddenTypes: [],
        ruleFailures: [`schema error: ${parsed.error.issues.map((i) => `${i.path.join(".")} ${i.message}`).join("; ")}`],
      });
      continue;
    }

    results.push(evaluateSampleResult(sample, parsed.data));
  }

  return results;
}

type RunParseSmokeOptions = {
  baseUrl?: string;
  timezone?: string;
  samples?: ParserSmokeSample[];
  fetchFn?: FetchLike;
};

function printResults(results: SmokeSampleResult[]): void {
  let passCount = 0;
  let reviewCount = 0;
  let typeFailCount = 0;
  let schemaErrorCount = 0;

  for (const result of results) {
    const hasSchemaError = result.ruleFailures.some((f) =>
      f.startsWith("schema error") || f === "HTTP request failed" || f.startsWith("HTTP ") || f === "response is not valid JSON",
    );

    if (hasSchemaError) {
      schemaErrorCount++;
      console.log(
        `ERR  ${result.sampleId} (${result.label}) -> ${result.ruleFailures.join("; ")}`,
      );
      continue;
    }

    const hasTypeFail =
      result.missingTypes.length > 0 || result.forbiddenTypes.length > 0;
    const hasRuleFail =
      result.ruleFailures.length > 0;

    if (hasTypeFail) {
      typeFailCount++;
      const actual = result.actualTypes.join(", ") || "none";
      console.log(
        `FAIL ${result.sampleId} (${result.label}) -> ${actual}`,
      );
      for (const mt of result.missingTypes) {
        console.log(`  missing: ${mt}`);
      }
      for (const ft of result.forbiddenTypes) {
        console.log(`  forbidden: ${ft}`);
      }
      for (const rf of result.ruleFailures) {
        console.log(`  rule: ${rf}`);
      }
    } else if (hasRuleFail) {
      reviewCount++;
      const actual = result.actualTypes.join(", ") || "none";
      console.log(
        `REVW ${result.sampleId} (${result.label}) -> ${actual}`,
      );
      for (const rf of result.ruleFailures) {
        console.log(`  rule: ${rf}`);
      }
    } else {
      passCount++;
      const actual = result.actualTypes.join(", ") || "none";
      console.log(`PASS ${result.sampleId} (${result.label}) -> ${actual}`);
    }
  }

  const total = results.length;
  console.log(`\n${total} samples checked`);
  console.log(`${passCount} pass`);
  console.log(`${reviewCount} need review`);
  console.log(`${typeFailCount} type mismatch`);
  console.log(`${schemaErrorCount} schema error`);

  if (typeFailCount > 0 || schemaErrorCount > 0) {
    process.exitCode = 1;
  }
}

async function main(): Promise<void> {
  const results = await runParseSmoke();
  printResults(results);
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  main().catch((error: unknown) => {
    const message =
      error instanceof Error ? error.message : "Unknown smoke error";
    console.error(message);
    process.exitCode = 1;
  });
}
