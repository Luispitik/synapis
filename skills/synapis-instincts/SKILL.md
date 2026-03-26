# Synapis Instincts v1.0

> Knowledge base that stores learned rules (instincts).
> Instincts are the atomic unit of Synapis knowledge --
> each one encodes a validated trigger-action pattern.
> THIS SKILL IS ALWAYS ACTIVE. Apply instincts automatically.

---

## What Is an Instinct?

An instinct is a validated behavioral pattern:

```
WHEN [trigger condition]
THEN [action to take]
CONFIDENCE: [0.0 - 1.0]
DOMAIN: [category tag]
SCOPE: [project | global]
```

**Examples:**
- WHEN writing SQL migrations THEN always include rollback statements (confidence: 0.9)
- WHEN creating API endpoints THEN add input validation middleware (confidence: 0.85)
- WHEN the user says "ship it" THEN run tests before deploying (confidence: 0.95)

---

## Instinct Lifecycle

```
Observation --> Hypothesis --> Pattern --> Instinct --> Law
  (0.0-0.3)    (0.3-0.5)    (0.5-0.7)   (0.7-0.9)  (0.9-1.0)
```

### Stages

1. **Observation** (0.0-0.3)
   - Raw detection from a single session
   - Not yet validated, might be noise
   - Stored but not applied automatically

2. **Hypothesis** (0.3-0.5)
   - Seen 2+ times across sessions
   - Plausible but needs more evidence
   - Applied only when explicitly relevant

3. **Pattern** (0.5-0.7)
   - Consistent across 3+ occurrences
   - High likelihood of being correct
   - Applied when context matches

4. **Instinct** (0.7-0.9)
   - Validated through repeated use
   - Applied automatically when triggered
   - Candidate for evolution to skill/command/rule

5. **Law** (0.9-1.0)
   - Proven across multiple projects
   - Always applied without question
   - Core part of the knowledge base

---

## Storage Format

Instincts are stored in `~/.claude/skills/_instincts.json`:

```json
{
  "version": "1.0",
  "lastUpdated": "2025-02-20T14:30:00Z",
  "instincts": {
    "global": [
      {
        "id": "inst_g001",
        "trigger": "When creating database tables",
        "action": "Always add created_at and updated_at timestamp columns",
        "confidence": 0.92,
        "domain": "development",
        "tags": ["database", "schema", "best-practice"],
        "firstSeen": "2025-01-10",
        "lastSeen": "2025-02-18",
        "occurrences": 12,
        "source": "observation",
        "evolvedTo": null,
        "history": [
          {"date": "2025-01-10", "confidence": 0.3, "event": "first-seen"},
          {"date": "2025-01-15", "confidence": 0.5, "event": "repeated"},
          {"date": "2025-02-01", "confidence": 0.7, "event": "user-validated"},
          {"date": "2025-02-18", "confidence": 0.92, "event": "cross-project"}
        ]
      }
    ],
    "projects": {
      "my-webapp": [
        {
          "id": "inst_p001",
          "trigger": "When writing API error responses",
          "action": "Use the AppError class with status code and error code fields",
          "confidence": 0.75,
          "domain": "development",
          "tags": ["api", "error-handling"],
          "firstSeen": "2025-02-01",
          "lastSeen": "2025-02-20",
          "occurrences": 5,
          "source": "correction",
          "evolvedTo": null,
          "history": []
        }
      ]
    }
  }
}
```

---

## Global vs Project Scope

### Global Instincts
- Apply to ALL projects
- Stored in the `global` array
- Typically reach global scope through `/promote`
- Must have confidence >= 0.7 to promote
- Examples: coding conventions, security practices, documentation style

### Project Instincts
- Apply only within a specific project
- Stored under `projects.{project-name}`
- Contain project-specific knowledge
- Examples: custom error classes, specific API patterns, deploy procedures

### Promotion Rules
- Instinct must have confidence >= 0.7
- Must have been observed in 2+ projects OR user-validated
- Use `/promote` command to move from project to global
- Promoted instincts retain their full history

---

## Applying Instincts

### Automatic Application (confidence >= 0.7)

When a trigger condition matches the current context:
1. Apply the instinct's action silently
2. Increment the `occurrences` counter
3. Update `lastSeen` timestamp
4. If this is the first time in a new project, note it in observations

### Suggested Application (confidence 0.5-0.7)

When a trigger condition matches but confidence is moderate:
1. Suggest the action to the user
2. If accepted: boost confidence by +0.1
3. If rejected: reduce confidence by -0.1

### Passive Application (confidence < 0.5)

Do not apply or suggest. Only log if the pattern appears again.

---

## Conflict Resolution

When two instincts contradict:

1. **Higher confidence wins** -- apply the instinct with higher score
2. **Narrower scope wins** -- project-specific overrides global
3. **More recent wins** -- if confidence is equal, prefer the one with more recent `lastSeen`
4. **Flag for review** -- if the conflict is unclear, log it and ask the user

```
INSTINCT CONFLICT DETECTED

  Instinct A (conf: 0.8): "Always use server components for data fetching"
  Instinct B (conf: 0.75): "Use client components when state is needed"

  These may not actually conflict. Context: current component needs both data and state.

  [A] Apply A  [B] Apply B  [M] Merge into new instinct  [X] Skip
```

---

## Commands

### /instinct-status

Show all instincts with their current state:

```
INSTINCT STATUS

  GLOBAL INSTINCTS (15 total)

  Laws (>= 0.9):
    inst_g001  [0.92] DB tables -> always add timestamps     (12 hits)
    inst_g002  [0.91] API routes -> validate input first      (18 hits)

  Instincts (0.7 - 0.9):
    inst_g003  [0.85] Commits -> conventional commit format    (8 hits)
    inst_g004  [0.78] Tests -> use real DB, not mocks          (6 hits)

  Patterns (0.5 - 0.7):
    inst_g005  [0.65] Deploys -> check env vars before push    (4 hits)

  Hypotheses (0.3 - 0.5):
    inst_g006  [0.40] Errors -> log context with stack trace   (2 hits)

  PROJECT: my-webapp (8 instincts)
  ...

  Total: 23 instincts | 5 laws | 8 instincts | 6 patterns | 4 hypotheses
```

### /promote

Move a project instinct to global scope:

```
Select instinct to promote to global:

  1. [0.82] API errors -> use AppError class
  2. [0.75] Auth -> always check session expiry
  3. [0.71] Forms -> validate client-side first

  Enter number or [A] Promote all eligible  [X] Cancel
```

---

## Integration Points

- **Synapis Learning**: Creates instincts from observations
- **Skill Router**: Uses instinct domains to recommend skills
- **Synapis Optimizer**: Reports instinct count in token budget
- **/evolve**: Clusters mature instincts into skills/commands
- **Passive Rules**: Instincts with confidence 1.0 become rule candidates
