# Changelog

## v4.1 — 2026-03-31

### New: Closed Learning Pipeline
The observation→learning→injection pipeline is now fully connected end-to-end:

1. `observe.sh` (PreToolUse + PostToolUse): writes `observations.jsonl` per project
2. `_session-learner.sh` (Stop hook): reads observations, detects error patterns, writes `_instinct-proposals.json`
3. `/analyze-session`: review proposals, accept → add to `_instincts-index.json`
4. `_instinct-activator.sh` (PreToolUse): reads index, injects matched instincts as `systemMessage`

### New: Project Context Bridge
`_session-learner.sh` writes `context.md` per project at session end (project name, last session date, files touched, gotcha count hint).
`_project-context.sh` reads it at the first PreToolUse of the next session — fires once per session via session_id flag.

### New: Domain Deduplication in Instinct Activator
`_instinct-activator.sh` groups instincts by domain. One instinct per domain is injected, max 3 total.
Prevents multiple contradictory instincts from the same area firing simultaneously.
Priority: `permanent` > `confirmed`.

### New: 3-Level Confidence Model
Replaces the 0.0–1.0 decimal scoring with 3 explicit levels:
- `draft`: proposed by session-learner, not injected. Review with `/analyze-session`.
- `confirmed`: validated by user. Injected silently when trigger matches.
- `permanent`: explicitly promoted via `/promote`. Highest priority in domain dedup.

### New: `_instincts-index.json`
Central instinct registry. Replaces scattered YAML files.
Fields: `id`, `domain`, `level`, `trigger_pattern`, `inject`, `origin`, `added`.
Origin values: `manual` (curated) or `learned` (from session-learner).

### New: `core/settings.template.json`
Documents the 7-hook architecture with comments. Copy/merge into `~/.claude/settings.json`.

### Changed: Honest Observation Model
v3.2 claimed Sinapsis "observes passively in real-time." This was inaccurate.
v4.1 is explicit: hooks are deterministic bash scripts. Claude does NOT analyze observations during a session.
Analysis happens at Stop (deterministic) or on demand (`/analyze-session`).

### Changed: Token Architecture
- 2 global skills always active (was 5): skill-router + sinapsis-learning
- Instinct injection: ~50–200 tokens per matching tool use (only matched instincts)
- Passive rules: ~20–80 tokens per matching tool use (only matched rules)
- Full `_instincts-index.json` and `_passive-rules.json` read by hooks, not loaded into LLM context

### Fixed: Noise in Proposals
v3.2 session-learner generated 80+ noise proposals per day (workflow sequences, tool preferences).
v4.1 only detects `error_resolution` patterns (error → same tool success within 5 events), with dedup per tool per day.

---

## v3.2 — Initial public release

Skills on Demand architecture. Passive rules, skill router, operator state, 5 global always-on skills.
