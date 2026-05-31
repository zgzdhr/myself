import cors from "cors";
import "dotenv/config";
import express from "express";

import { createParseRouter } from "./routes/parse.js";
import { createDeepSeekParser } from "./services/deepseekParser.js";

const app = express();
const port = Number(process.env.API_PORT ?? 8787);

app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_request, response) => {
  response.json({ ok: true });
});

app.use(createParseRouter(createDeepSeekParser()));

app.listen(port, () => {
  console.log(`API proxy listening on port ${port}`);
});
