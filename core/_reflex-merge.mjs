#!/usr/bin/env node
// Sinapsis v4.5 — Reflex Merger
//
// Merges seed passive rules (seeds/reflexes.json) into the user's
// ~/.claude/skills/_passive-rules.json. Idempotent — rules with an id that
// already exists in the user's index are skipped (user customizations win).
//
// Inspired by fs-cortex reflex tier — credit: Fernando Montero (MIT, 2026).
//
// Usage:
//   node core/_reflex-merge.mjs [--seeds-path <path>] [--index-path <path>] [--dry-run]

import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const out = { seedsPath: null, indexPath: null, dryRun: false };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--seeds-path") out.seedsPath = argv[++i];
    else if (a === "--index-path") out.indexPath = argv[++i];
    else if (a === "--dry-run") out.dryRun = true;
  }
  return out;
}

function defaultSeedsPath() {
  const repoSeed = path.join(__dirname, "..", "seeds", "reflexes.json");
  if (fs.existsSync(repoSeed)) return repoSeed;
  return null;
}

function defaultIndexPath() {
  const home = process.env.SINAPSIS_HOME || path.join(process.env.HOME || process.env.USERPROFILE, ".claude");
  return path.join(home, "skills", "_passive-rules.json");
}

function atomicWrite(filePath, text) {
  const tmp = filePath + ".tmp";
  fs.writeFileSync(tmp, text);
  // Preserve existing file mode (install.sh hardens this file to 0600).
  // If target does not exist yet (fresh install), fall back to the explicit
  // Sinapsis default 0o600 to match install.sh's documented protection.
  try {
    const mode = fs.existsSync(filePath) ? fs.statSync(filePath).mode & 0o777 : 0o600;
    fs.chmodSync(tmp, mode);
  } catch (e) { /* best-effort on platforms without POSIX modes (Windows) */ }
  fs.renameSync(tmp, filePath);
}

const args = parseArgs(process.argv);
const seedsPath = args.seedsPath || defaultSeedsPath();
const indexPath = args.indexPath || defaultIndexPath();

if (!seedsPath || !fs.existsSync(seedsPath)) {
  console.error(`ERROR: seeds file missing: ${seedsPath}`);
  process.exit(1);
}
if (!fs.existsSync(indexPath)) {
  console.error(`ERROR: passive rules index missing: ${indexPath}`);
  process.exit(1);
}

const seeds = JSON.parse(fs.readFileSync(seedsPath, "utf8"));
const index = JSON.parse(fs.readFileSync(indexPath, "utf8"));

if (!Array.isArray(index.rules)) index.rules = [];

const existing = new Set(index.rules.map(r => r.id));
const imported = [];
const already = [];

for (const rule of seeds.rules || []) {
  if (!rule.id) continue;
  if (existing.has(rule.id)) {
    already.push(rule.id);
    continue;
  }
  index.rules.push(rule);
  imported.push(rule.id);
}

// Recompute totalTokens
const totalTokens = index.rules.reduce((sum, r) => sum + (Number(r.tokens) || 0), 0);
index.totalTokens = totalTokens;

if (args.dryRun) {
  console.log("[DRY-RUN] No files modified.");
} else if (imported.length > 0) {
  atomicWrite(indexPath, JSON.stringify(index, null, 2) + "\n");
  console.log(`[OK] Wrote ${indexPath}`);
}

console.log(`Imported (${imported.length}):`);
for (const id of imported) console.log(`  + ${id}`);
if (already.length) console.log(`Already present (${already.length}): ${already.join(", ")}`);
