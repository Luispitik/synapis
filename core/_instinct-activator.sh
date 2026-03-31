#!/bin/bash
# Instinct Activator - Sinapsis v4.1
# PreToolUse hook (async, 5s): reads _instincts-index.json, matches against
# current tool context, injects matched instincts as systemMessage.
# Domain dedup: one instinct per domain, max 3. Never injects drafts.

INDEX="$HOME/.claude/skills/_instincts-index.json"
[ ! -f "$INDEX" ] && exit 0

node -e '
const fs = require("fs");

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", chunk => input += chunk);
process.stdin.on("end", () => {
  let data;
  try { data = JSON.parse(input); } catch(e) { process.exit(0); }

  let idx;
  try { idx = JSON.parse(fs.readFileSync(process.argv[1], "utf8")); } catch(e) { process.exit(0); }

  const instincts = idx.instincts || [];
  if (instincts.length === 0) process.exit(0);

  // Build context string from tool name + input content
  const tool = data.tool_name || "";
  let inputContent = "";
  try {
    const inp = data.tool_input || {};
    inputContent = [inp.command, inp.file_path, inp.pattern, inp.prompt, inp.content]
      .filter(Boolean).join(" ").slice(0, 300);
  } catch(e) {}
  const context = (tool + " " + inputContent).toLowerCase();

  // Match instincts: skip drafts, test trigger_pattern against context
  const matches = [];
  for (const inst of instincts) {
    if (!inst.trigger_pattern) continue;
    if (inst.level === "draft") continue; // drafts are never auto-injected
    try {
      if (!new RegExp(inst.trigger_pattern, "i").test(context)) continue;
    } catch(e) { continue; }
    matches.push(inst);
  }

  if (matches.length === 0) process.exit(0);

  // Sort: permanent first, then confirmed
  const order = { permanent: 0, confirmed: 1 };
  matches.sort((a, b) => (order[a.level] ?? 2) - (order[b.level] ?? 2));

  // Domain dedup: one instinct per domain, max 3 total
  const domainMap = {};
  for (const m of matches) {
    const d = m.domain || "_default";
    if (!domainMap[d]) domainMap[d] = m;
  }
  const top = Object.values(domainMap).slice(0, 3);
  if (top.length === 0) process.exit(0);

  const msgs = top.map(m => "[instinct] " + m.inject);
  console.log(JSON.stringify({ systemMessage: msgs.join("\n") }));
});
' "$INDEX" 2>/dev/null

exit 0
