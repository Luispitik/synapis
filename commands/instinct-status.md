# /instinct-status -- Instinct Dashboard

> Show all instincts (project + global) with confidence scoring,
> lifecycle stage, and evolution readiness.

---

## Trigger

Run with `/instinct-status` or "show my instincts".

---

## Process

1. Read `~/.claude/skills/_instincts.json`
2. Separate global vs project instincts
3. Group by lifecycle stage
4. Sort by confidence descending within each group
5. Display dashboard

---

## Dashboard Format

```
INSTINCT STATUS

  Total: 43 instincts (15 global + 28 project)
  Evolution candidates: 4 (confidence >= 0.7, not yet evolved)

  ============================================
  GLOBAL INSTINCTS (15)
  ============================================

  LAWS (confidence >= 0.9)
  ──────────────────────
  ID         Conf   Hits  Domain        Trigger -> Action
  inst_g001  0.92   12    development   DB tables -> add timestamps
  inst_g002  0.91   18    development   API routes -> validate input first
  inst_g003  0.90   47    workflow      Commits -> conventional format

  INSTINCTS (confidence 0.7 - 0.9)
  ──────────────────────────────────
  inst_g004  0.85    8    deployment    Before deploy -> run tests
  inst_g005  0.82    6    deployment    Before deploy -> check env vars
  inst_g006  0.78    5    testing       Tests -> use real DB, not mocks
  inst_g007  0.75   11    development   Errors -> include error code

  PATTERNS (confidence 0.5 - 0.7)
  ────────────────────────────────
  inst_g008  0.65    4    deployment    Deploy -> verify migrations
  inst_g009  0.60    3    security      Auth -> check session expiry
  inst_g010  0.55    2    documentation Docs -> include code examples

  HYPOTHESES (confidence 0.3 - 0.5)
  ──────────────────────────────────
  inst_g011  0.40    2    debugging     Errors -> log context with stack
  inst_g012  0.35    1    performance   DB queries -> add index hints

  OBSERVATIONS (confidence < 0.3)
  ────────────────────────────────
  inst_g013  0.20    1    design        Components -> prefer composition
  inst_g014  0.15    1    workflow      PR -> add screenshots
  inst_g015  0.10    1    testing       E2E -> test happy path first

  ============================================
  PROJECT: {current-project} (28 instincts)
  ============================================

  [Similar breakdown by lifecycle stage...]

  ============================================
  EVOLUTION READY (4 candidates)
  ============================================
  inst_g004  [0.85] + inst_g005 [0.82] + inst_g008 [0.65]
    -> Potential cluster: "Deployment Checklist"
    -> Run /evolve to process

  inst_p001  [0.82]
    -> Solo candidate: "API Error Handling"
    -> Run /evolve to process

  ============================================
  Actions:
  [E] /evolve        -- Process evolution candidates
  [P] /promote       -- Promote project instincts to global
  [D] Delete         -- Remove an instinct by ID
  [X] Close
```
