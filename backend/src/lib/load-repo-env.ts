import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { config as loadEnv } from "dotenv";

function findRepoEnv(): string | null {
  const metaRepoEnv = import.meta.dirname
    ? resolve(import.meta.dirname, "../../../.env")
    : null;
  const candidates = [
    metaRepoEnv,
    resolve(process.cwd(), ".env"),
    resolve(process.cwd(), "../.env"),
  ].filter((p): p is string => Boolean(p));

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}

/** Loads repo-root `.env` when present (local scripts / npm run dev). Docker injects env directly. */
export function loadRepoEnv(): void {
  const envPath = findRepoEnv();
  if (envPath) {
    loadEnv({ path: envPath });
  }
}

/** Loads only DATABASE_URL from repo-root `.env` for tests that import DB modules without a live Postgres. */
export function loadRepoDatabaseUrl(): void {
  if (process.env.DATABASE_URL) return;

  const envPath = findRepoEnv();
  if (!envPath) return;

  const match = readFileSync(envPath, "utf8").match(/^DATABASE_URL=(.+)$/m);
  if (match?.[1]) {
    process.env.DATABASE_URL = match[1].trim();
  }
}
