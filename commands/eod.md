# /eod -- End of Day Summary (Multi-Project)

> Save your work context for tomorrow across ALL projects worked today.
> Next session, Claude greets you with what you did and what's next.
> Never lose context between sessions again.

---

## Trigger

Run with `/eod`, "end of day", "save for tomorrow", "wrap up", or "guardar sesion".

**Flags:**
- `/eod --quick` — Auto-generate from gathered data only, skip user input
- `/eod --yesterday` — Show the most recent saved summary

---

## Process

### Step 1: Gather Multi-Project Data (automatic)

Run the multi-project gather script to detect ALL projects worked today:

```bash
bash ~/.claude/skills/_eod-gather.sh
```

This scans `~/.claude/homunculus/projects/` for observations from today, cross-references with `projects.json` for names and roots, runs git commands against each project root, and outputs structured JSON.

The output includes per-project: name, observation count, tools used, files touched, errors, git commits, branch, and uncommitted changes.

If the script is not available or returns 0 projects, fall back to scanning the current project directory only (legacy mode):

```bash
AUTHOR=$(git config user.email 2>/dev/null)
if [ -n "$AUTHOR" ]; then
  git log --oneline --since="00:00" --author="$AUTHOR"
else
  git log --oneline --since="00:00"
fi
git branch --show-current 2>/dev/null
git status -s 2>/dev/null
```

Also gather Sinapsis learning state:
- Read `~/.claude/skills/_instincts-index.json` — count instincts with `last_triggered` = today
- Read `~/.claude/skills/_instinct-proposals.json` — count proposals from today

### Step 2: Ask for Priorities (unless --quick)

If `--quick` was NOT passed, ask the user:

```
What should we focus on tomorrow? Any priorities, blockers, or notes to carry over?
(Press Enter to skip — I'll generate priorities from activity data)
```

If user provides input: include it verbatim in "For tomorrow" section.
If user skips: auto-generate priorities from uncommitted files, open PRs, and recent patterns.

### Step 3: Generate Summary

Compose the summary in this exact format:

```markdown
# EOD — {YYYY-MM-DD}

## Projects Worked Today: {count}

### {project-1-name}
Branch: {current-branch}
Observations: {count} | Errors: {count}

**What was done**
- {Summary of each commit, grouped by theme}
- {Files touched during session}

**Pending**
- {Uncommitted files, if any}

---

### {project-2-name}
Branch: {current-branch}
...

(repeat for each project)

---

## Cross-Project Summary

### For tomorrow
- {Priority 1}
- {Priority 2}
- {Priority 3}

### Sinapsis Learning
- Instincts triggered today: {count}
- New proposals: {count}
- Observations total: {count across all projects}

### Notes
- {User-provided carry-over notes}
- {Any important context detected from the session}

## Quick Resume
> "{1-2 sentence summary in the user's preferred language.
> Include: projects worked, what was accomplished, and top priority for tomorrow.
> This gets injected at the start of the next session.}"
```

### Step 4: Save to Disk

Write the summary to:
```
~/.claude/skills/_daily-summaries/{YYYY-MM-DD}.md
```

Create the `_daily-summaries` directory if it does not exist.

### Step 5: Display Confirmation

Show a compact visual summary:

```
======================================================
  EOD — {YYYY-MM-DD}
======================================================

  PROJECTS WORKED: {N}
  ──────────────────────────
  {project-1}: {branch} | {N} commits | {N} pending
  {project-2}: {branch} | {N} commits | {N} pending
  ...

  TOTAL OBSERVATIONS: {N} across {N} projects

  FOR TOMORROW:
  1. {Priority 1}
  2. {Priority 2}
  3. {Priority 3}

  SINAPSIS: +{N} observations | +{N} instincts triggered

  Saved: ~/.claude/skills/_daily-summaries/{date}.md

  Tomorrow, I'll greet you with this summary automatically.
======================================================
```

---

## Edge Cases

- **No homunculus data**: Fall back to current project git scan only.
- **No git in a project root**: Skip git data for that project, show observation data only.
- **No gh CLI**: Skip PR data silently, continue with everything else.
- **No activity today**: Show: "No activity detected today across any project. Want to save notes for tomorrow anyway?"
- **Already saved today**: Show: "EOD already saved for today. Overwrite with updated data? (y/n)"
- **Single project only**: Format as before but using gather script data.
- **--yesterday flag**: List files with `ls -t ~/.claude/skills/_daily-summaries/*.md 2>/dev/null | head -1` to find the most recent summary, then Read that file. If no files exist, show: "No EOD summaries saved yet. Run /eod to create your first one."

---

## How Resume Works (next session)

The `_project-context.sh` hook reads yesterday's summary at session start.

When a Quick Resume exists, Claude's first response follows this pattern:

```
Welcome back! Here's where we left off:

{Paraphrased Quick Resume — what was done yesterday}

Priorities for today:
1. {From "For tomorrow" section}
2. {From "For tomorrow" section}

Where do you want to start?
```

---

## What NOT to Do

- Do not invent activity that did not happen — use gather script data and user input only
- Do not modify any project files or code
- Do not run tests, builds, or any side-effect commands
- Do not overwrite an existing summary without asking
- Do not include sensitive data (env vars, tokens, passwords) in the summary
