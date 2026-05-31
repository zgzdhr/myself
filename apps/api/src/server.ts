import cors from "cors";
import "dotenv/config";
import express from "express";

import { createParseRouter } from "./routes/parse.js";

const app = express();
const port = Number(process.env.API_PORT ?? 8787);

app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_request, response) => {
  response.json({ ok: true });
});

app.use(
  createParseRouter(async () => {
    throw new Error("Parser service is not configured yet.");
  }),
);

app.listen(port, () => {
  console.log(`API proxy listening on port ${port}`);
});
