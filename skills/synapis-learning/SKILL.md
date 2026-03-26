# Synapis Learning v1.0

> Continuous learning engine. Observes sessions passively, detects patterns,
> captures instincts, and feeds the evolution pipeline.
> This skill is ALWAYS ACTIVE -- it runs in the background of every session.

---

## Core Concept

Synapis Learning watches how the user works with Claude and captures **instincts**:
atomic, reusable patterns that encode "when X happens, do Y" knowledge.

Over time, instincts mature through confidence scoring and can be evolved into
full skills, commands, agents, or passive rules via `/evolve`.

---

## Operating Modes

### 1. Passive Observation (Always On)

Every session, Synapis silently observes:

- **Corrections**: User corrects Claude's output --> potential instinct
- **Repetitions**: Same pattern appears 3+ times --> strong instinct candidate
- **Preferences**: User consistently chooses A over B --> preference instinct
- **Workarounds**: User applies a non-obvious fix --> gotcha instinct
- **Tool chains**: User always runs tools in sequence X->Y->Z --> workflow instinct
- **Rejections**: User rejects Claude's suggestion --> anti-pattern instinct

**Rule**: Never interrupt the user to report observations. Log silently.

### 2. Active Capture (On Request)

Triggered when user says:
- "Learn this", "Remember this pattern", "Save this as instinct"
- "This is how I always do X"
- "Never do Y again"

Active capture creates an instinct immediately with confidence 0.8 (user-validated).

### 3. Analysis Mode

Triggered by `/analyze-observations` or "what have you learned?".

Reviews the observation log and:
- Clusters related observations
- Proposes new instincts
- Identifies instincts ready for evolution
- Suggests passive rules

---

## Pattern Detection

### Detection Rules

| Signal | Confidence Boost | Example |
|--------|-----------------|---------|
| User explicitly says "always/never" | +0.3 | "Always use TypeScript" |
| Pattern seen 2x | +0.1 | Same fix applied twice |
| Pattern seen 3x | +0.2 | Third time same pattern |
| Pattern seen 5x+ | +0.3 | Consistent behavior |
| User corrects Claude | +0.2 | "No, do it like this" |
| Pattern matches existing instinct | +0.1 | Reinforcement |
| Pattern contradicts existing instinct | flag for review | Conflict detected |

### Confidence Scoring

Every instinct has a confidence score from 0.0 to 1.0:

```
0.0 - 0.3  : Observation (raw, unvalidated)
0.3 - 0.5  : Hypothesis (seen multiple times, not yet confirmed)
0.5 - 0.7  : Pattern (consistent, likely correct)
0.7 - 0.9  : Instinct (validated, reliable)
0.9 - 1.0  : Law (proven across multiple projects/sessions)
```

Confidence increases through:
- Repeated observation (+0.1 per occurrence, max +0.3)
- User validation (+0.2)
- Cross-project confirmation (+0.2)
- Time stability (instinct holds true over 5+ sessions: +0.1)

Confidence decreases through:
- Contradiction by user (-0.2)
- Failed application (-0.1)
- Staleness (no observation in 30+ days: -0.05)

---

## Instinct Capture Format

When a pattern is detected, capture it as:

```json
{
  "id": "inst_a1b2c3",
  "trigger": "When deploying a Next.js app to Vercel",
  "action": "Always check for middleware compatibility",
  "confidence": 0.6,
  "domain": "deployment",
  "tags": ["nextjs", "vercel", "middleware"],
  "scope": "project",
  "source": "observation",
  "firstSeen": "2025-01-15",
  "lastSeen": "2025-02-20",
  "occurrences": 4,
  "project": "my-webapp"
}
```

### Domain Tags

Instincts are tagged with domains for organization:

- `development` -- coding patterns, architecture decisions
- `deployment` -- CI/CD, hosting, infrastructure
- `testing` -- test strategies, assertion patterns
- `documentation` -- doc style, structure preferences
- `workflow` -- process patterns, tool chains
- `communication` -- writing style, response format
- `debugging` -- troubleshooting approaches
- `design` -- UI/UX patterns, component choices
- `data` -- data handling, transformations
- `security` -- auth patterns, vulnerability awareness
- `performance` -- optimization techniques
- `custom:{tag}` -- user-defined domains

---

## Observation Logging

Observations are stored in `~/.claude/skills/_observations.json`:

```json
{
  "observations": [
    {
      "id": "obs_x1y2z3",
      "timestamp": "2025-02-20T14:30:00Z",
      "session": "session-id",
      "project": "project-name",
      "type": "correction|repetition|preference|workaround|rejection",
      "description": "User corrected API error handling to use custom error class",
      "context": "While building REST endpoint",
      "relatedInstinct": "inst_a1b2c3",
      "promoted": false
    }
  ]
}
```

### Log Rotation

- Keep last 500 observations in active log
- Archive older observations to `_observations_archive.json`
- Aggregate archived observations into instinct confidence scores

---

## Integration with /evolve

When instincts reach confidence >= 0.7, they become candidates for evolution.

The `/evolve` command reads mature instincts and proposes:
- **[S]kill**: Create a new reusable skill from clustered instincts
- **[C]ommand**: Create a slash command for a repeated workflow
- **[A]gent**: Create an autonomous agent for complex patterns
- **[R]ule**: Create a passive rule that fires automatically
- **[E]nrich**: Add to an existing skill's knowledge
- **[P]romote**: Move from project scope to global scope

See `/evolve` command for full details.

---

## Privacy & Data

- All observations stay local (no external transmission)
- No personal data is captured in instincts -- only patterns
- Instinct `trigger` and `action` fields describe behavior, not content
- Users can delete any instinct or observation at any time
- `/instinct-status` shows everything that has been learned

---

## Commands

| Command | Action |
|---------|--------|
| "Learn this" | Capture current pattern as instinct |
| "What have you learned?" | Show learning summary |
| `/instinct-status` | Show all instincts with confidence |
| `/analyze-observations` | Deep analysis of observation log |
| `/evolve` | Promote mature instincts to skills/commands |
| `/promote` | Move instinct from project to global scope |

---

## Self-Healing Integration

When Synapis detects a repeated error pattern:

1. Log as observation with type `workaround`
2. If the same error+fix appears 3x, create instinct automatically
3. If instinct confidence reaches 0.8, suggest as passive rule
4. Passive rule auto-applies the fix without asking

This creates a **self-healing loop**: errors become knowledge become automatic fixes.
