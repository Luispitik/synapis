#!/bin/bash
# Session Learner - Sinapsis v4.1
# Stop hook (15s): two jobs —
#   1. Write context.md per project → injected at next session start
#   2. Detect error-resolution patterns → write _instinct-proposals.json
# NO LLM. Pure deterministic Node.js.

HOMUNCULUS="$HOME/.claude/homunculus"
INDEX_FILE="$HOME/.claude/skills/_instincts-index.json"
PROPOSALS_FILE="$HOME/.claude/skills/_instinct-proposals.json"
LOG_FILE="$HOME/.claude/skills/_session-learner.log"

# Find the most recent observations file
OBS_FILE=""
if [ -d "$HOMUNCULUS/projects" ]; then
  OBS_FILE=$(find "$HOMUNCULUS/projects" -name "observations.jsonl" -newer "$HOMUNCULUS/.last-learn" 2>/dev/null | head -1)
  [ -z "$OBS_FILE" ] && OBS_FILE=$(find "$HOMUNCULUS/projects" -name "observations.jsonl" -size +0c 2>/dev/null | sort -t/ -k6 | tail -1)
fi

[ -z "$OBS_FILE" ] && exit 0
[ ! -s "$OBS_FILE" ] && exit 0

node -e '
const fs = require("fs");
const path = require("path");

const obsFile = process.argv[1];
const indexFile = process.argv[2];
const proposalsFile = process.argv[3];
const logFile = process.argv[4];

// Read last 100 lines of observations
let lines;
try {
  const content = fs.readFileSync(obsFile, "utf8").trim().split("\n");
  lines = content.slice(-100).map(l => { try { return JSON.parse(l); } catch(e) { return null; } }).filter(Boolean);
} catch(e) { process.exit(0); }

if (lines.length < 3) process.exit(0);

// ── JOB 1: Write project context.md (ALWAYS — not just when proposals exist) ──
const projectDir = path.dirname(obsFile);
const projectHash = path.basename(projectDir);
const today = new Date().toISOString().slice(0, 10);

try {
  let totalObs = lines.length;
  try {
    totalObs = fs.readFileSync(obsFile, "utf8").trim().split("\n").length;
  } catch(e) {}

  // Get project name from homunculus/projects.json if available
  let projectName = projectHash;
  try {
    const pj = JSON.parse(fs.readFileSync(process.env.HOME + "/.claude/homunculus/projects.json", "utf8"));
    if (pj[projectHash] && pj[projectHash].name) projectName = pj[projectHash].name;
  } catch(e) {}

  // Files touched this session (Edit/Write, deduplicated, max 6)
  const filesTouched = [...new Set(
    lines
      .filter(l => l.event === "tool_complete" && (l.tool === "Edit" || l.tool === "Write"))
      .map(l => {
        try {
          const inp = JSON.parse(l.input || "{}");
          return inp.file_path ? path.basename(inp.file_path) : null;
        } catch(e) { return null; }
      })
      .filter(Boolean)
  )].slice(0, 6);

  // Count error-resolution pairs (hints at gotchas)
  let errorCount = 0;
  for (let i = 0; i < lines.length - 1; i++) {
    if (!lines[i].is_error) continue;
    for (let j = i+1; j < Math.min(i+6, lines.length); j++) {
      if (lines[j].tool === lines[i].tool && !lines[j].is_error) { errorCount++; break; }
    }
  }

  const contextLines = [
    "## Project: " + projectName,
    "Last session: " + today,
    "Total observations: " + totalObs,
    filesTouched.length > 0 ? "Active files: " + filesTouched.join(", ") : null,
    errorCount > 0 ? "Possible gotchas detected: " + errorCount + " — run /analyze-session" : null,
  ].filter(Boolean).join("\n");

  fs.writeFileSync(projectDir + "/context.md", contextLines);
} catch(e) {
  // context.md write failure is non-critical
}

// ── JOB 2: Detect error-resolution patterns → proposals ──

// Read existing instincts to avoid re-proposing known patterns
let existing = new Set();
try {
  const idx = JSON.parse(fs.readFileSync(indexFile, "utf8"));
  (idx.instincts || []).forEach(i => existing.add(i.id));
} catch(e) {}

// Load proposals for today (session-based, overwrites on new day)
let proposals;
try {
  const raw = JSON.parse(fs.readFileSync(proposalsFile, "utf8"));
  proposals = (raw.session_date === today) ? raw : { version: "1.0", session_date: today, proposals: [] };
} catch(e) {
  proposals = { version: "1.0", session_date: today, proposals: [] };
}

const proposedIds = new Set(proposals.proposals.map(p => p.id));
const found = [];

// PATTERN: error → same tool success within 5 events (uses is_error flag)
// Dedup: one proposal per tool per day
for (let i = 0; i < lines.length - 1; i++) {
  if (!lines[i].is_error) continue;

  const toolId = "fix-" + lines[i].tool.toLowerCase().replace(/[^a-z]/g, "");
  if (existing.has(toolId) || proposedIds.has(toolId)) continue;

  for (let j = i+1; j < Math.min(i+6, lines.length); j++) {
    if (lines[j].tool === lines[i].tool && !lines[j].is_error) {
      found.push({
        type: "error_resolution",
        id: toolId,
        description: lines[i].tool + " error resolved — possible gotcha to document",
        evidence: "Session " + today + ": failure and recovery in same tool"
      });
      proposedIds.add(toolId);
      break;
    }
  }
}

const now = new Date().toISOString();

if (found.length > 0) {
  found.forEach(f => {
    proposals.proposals.push({ ...f, proposed_at: now, status: "pending", level: "draft" });
  });
  try { fs.writeFileSync(proposalsFile, JSON.stringify(proposals, null, 2)); } catch(e) {}
}

// Touch .last-learn marker
try { fs.writeFileSync(process.env.HOME + "/.claude/homunculus/.last-learn", now); } catch(e) {}

// Log
try {
  const summary = found.length > 0
    ? found.length + " patterns: " + found.map(f => f.id).join(",")
    : "no patterns";
  fs.appendFileSync(logFile, now + " | " + summary + " | context.md written for " + projectHash + "\n");
} catch(e) {}

// Output systemMessage only if proposals found
if (found.length > 0) {
  const msg = "Sinapsis: " + found.length + " pattern(s) detected:\n" +
    found.map(f => "  - " + f.description).join("\n") +
    "\nReview with /analyze-session.";
  console.log(JSON.stringify({ systemMessage: msg }));
}
' "$OBS_FILE" "$INDEX_FILE" "$PROPOSALS_FILE" "$LOG_FILE" 2>/dev/null

exit 0
