#!/bin/bash
# Project Context Injector - Sinapsis v4.1
# PreToolUse (sync, 3s): injects last-session summary for the current project.
# Fires ONCE per session using session_id as flag. Bridges context between sessions.
# Reads: homunculus/projects/{hash}/context.md
# Writes: nothing (read-only hook)

HOMUNCULUS="$HOME/.claude/homunculus"
[ ! -d "$HOMUNCULUS" ] && exit 0

node -e '
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const os = require("os");
const { execSync } = require("child_process");

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", chunk => input += chunk);
process.stdin.on("end", () => {
  let data;
  try { data = JSON.parse(input); } catch(e) { process.exit(0); }

  const sessionId = (data.session_id || "unknown").slice(0, 16);
  const cwd = data.cwd || "";

  // Fire only once per session (flag in os.tmpdir)
  const flagFile = path.join(os.tmpdir(), "sinapsis-ctx-" + sessionId);
  if (fs.existsSync(flagFile)) process.exit(0);
  try { fs.writeFileSync(flagFile, "1"); } catch(e) {}

  // Only works for git projects
  if (!cwd || !fs.existsSync(cwd)) process.exit(0);

  let projectHash;
  try {
    const root = execSync(
      "git -C " + JSON.stringify(cwd) + " rev-parse --show-toplevel",
      { stdio: ["pipe", "pipe", "pipe"], timeout: 3000 }
    ).toString().trim();
    let remote = "";
    try {
      remote = execSync(
        "git -C " + JSON.stringify(root) + " remote get-url origin",
        { stdio: ["pipe", "pipe", "pipe"], timeout: 2000 }
      ).toString().trim();
    } catch(e) {}
    // Hash the remote URL (or root path if no remote) — same logic as observe.sh
    projectHash = crypto.createHash("sha256").update(remote || root).digest("hex").slice(0, 12);
  } catch(e) {
    process.exit(0); // Not a git project or git not available
  }

  const contextFile = process.env.HOME + "/.claude/homunculus/projects/" + projectHash + "/context.md";
  if (!fs.existsSync(contextFile)) process.exit(0);

  let context;
  try { context = fs.readFileSync(contextFile, "utf8").trim(); } catch(e) { process.exit(0); }
  if (!context) process.exit(0);

  // Only inject if context is recent (< 14 days)
  try {
    const stats = fs.statSync(contextFile);
    const ageDays = (Date.now() - stats.mtimeMs) / 86400000;
    if (ageDays > 14) process.exit(0);
  } catch(e) {}

  console.log(JSON.stringify({
    systemMessage: "[project-context]\n" + context
  }));
});
' 2>/dev/null

exit 0
