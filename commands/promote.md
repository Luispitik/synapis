# /promote -- Promote Instincts to Global Scope

> Move project-scoped instincts to global scope so they apply everywhere.

---

## Trigger

Run with `/promote` or "promote instinct".

---

## Requirements

- Instinct must have confidence >= 0.7
- Instinct must be project-scoped (already global instincts cannot be promoted)
- Instinct should have been observed in 2+ projects OR be user-validated

---

## Process

### Step 1: Show Eligible Instincts

```
PROMOTE TO GLOBAL

  Eligible instincts from project "{current-project}":

  #  ID          Conf  Hits  Trigger -> Action
  1. inst_p001   0.82   5    API errors -> use AppError class
  2. inst_p003   0.78   4    Auth -> always check session expiry
  3. inst_p005   0.75   3    Forms -> validate client-side first
  4. inst_p008   0.71   3    Before deploy -> verify migrations

  Not eligible (confidence < 0.7):
  - inst_p002 [0.55] Caching -> invalidate on write (needs more evidence)
  - inst_p004 [0.40] Logging -> structured JSON format (hypothesis only)

  Select instincts to promote:
  Enter numbers (e.g., "1 3 4"), [A] All eligible, [X] Cancel
```

### Step 2: Confirm

```
  Promoting 3 instincts to global scope:

  1. inst_p001 -> Will apply to ALL projects as API error pattern
  2. inst_p003 -> Will apply to ALL projects as auth pattern
  3. inst_p005 -> Will apply to ALL projects as form pattern

  This means these patterns will be enforced everywhere.
  [Y] Confirm  [N] Cancel
```

### Step 3: Execute

1. Move instincts from `projects.{project}` to `global` in `_instincts.json`
2. Retain full history
3. Update `lastSeen` to current date
4. Add history entry: `{"date": "...", "event": "promoted-to-global"}`

### Step 4: Summary

```
PROMOTION COMPLETE

  3 instincts promoted to global scope.
  Global instincts: 15 -> 18
  Project instincts: 28 -> 25

  These patterns now apply to all projects automatically.
```
