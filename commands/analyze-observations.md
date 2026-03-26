# /analyze-observations -- Observation Analysis

> Analyze the Synapis observation log and suggest new instincts,
> skills, and passive rules based on patterns found.

---

## Trigger

Run with `/analyze-observations` or "analyze my observations".

---

## Process

### Step 1: Load Data

Read `~/.claude/skills/_observations.json` and gather:
- Total observation count
- Date range
- Type distribution (correction, repetition, preference, workaround, rejection)
- Domain distribution
- Already-linked instincts

### Step 2: Pattern Analysis

For unlinked observations (not yet converted to instincts):

1. **Frequency clustering**: Group observations with similar descriptions
2. **Temporal clustering**: Group observations that occur close in time
3. **Domain clustering**: Group by domain tags
4. **Correction chains**: Find sequences of corrections on same topic

### Step 3: Present Findings

```
OBSERVATION ANALYSIS

  Total observations: 312
  Unlinked (no instinct): 198
  Date range: 2025-01-10 to 2025-02-20

  ============================================
  SUGGESTED NEW INSTINCTS (8 found)
  ============================================

  1. "Error Logging Pattern" (seen 6x)
     Observations: obs_045, obs_089, obs_123, obs_156, obs_201, obs_267
     Pattern: User consistently adds context object to error logs
     Suggested instinct:
       WHEN logging errors
       THEN include { userId, requestId, timestamp } context
     Confidence: 0.6 (6 occurrences)
     [C] Create instinct  [X] Skip

  2. "TypeScript Strict Preference" (seen 4x)
     Observations: obs_034, obs_078, obs_145, obs_234
     Pattern: User corrects non-strict types to strict types
     Suggested instinct:
       WHEN writing TypeScript
       THEN use strict mode and explicit types (no 'any')
     Confidence: 0.5 (4 occurrences, all corrections)
     [C] Create instinct  [X] Skip

  [... more suggestions ...]

  ============================================
  SUGGESTED PASSIVE RULES (2 found)
  ============================================

  3. "Auto-format on save" (derived from instinct cluster)
     3 instincts all relate to code formatting
     Could be a single passive rule: auto-apply formatter
     [R] Create rule  [X] Skip

  ============================================
  SUGGESTED SKILLS (1 found)
  ============================================

  4. "Error Handling Patterns" (derived from 5 related instincts)
     Multiple instincts about error handling across projects
     Could be consolidated into a dedicated skill (~800 tokens)
     [S] Create skill via /evolve  [X] Skip

  ============================================
  CLEANUP SUGGESTIONS
  ============================================

  - 167 observations older than 30 days with no linked instinct
    These are likely noise or one-off events
    [A] Archive  [K] Keep  [R] Review one by one

  ============================================
  SUMMARY
  ============================================

  New instincts suggested: 8
  New passive rules suggested: 2
  New skills suggested: 1
  Archivable observations: 167

  Enter choices (e.g., "1C 2C 3R 4S archive"): _
```

### Step 4: Execute

For each accepted suggestion:
- **Create instinct**: Add to `_instincts.json` with suggested confidence
- **Create rule**: Add to `_passive-rules.json` with fireCount: 0
- **Create skill**: Redirect to `/evolve` with pre-selected instincts
- **Archive**: Move old observations to `_observations_archive.json`

### Step 5: Summary

```
ANALYSIS COMPLETE

  Created: 5 new instincts, 1 passive rule
  Archived: 167 stale observations
  Pending: 1 skill suggestion (run /evolve)

  Observation log: 312 -> 145 entries
  Instinct count: 43 -> 48
```
