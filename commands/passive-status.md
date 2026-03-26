# /passive-status -- Passive Rules Dashboard

> Show which passive rules are active, which fire most often,
> and which have never fired (candidates for removal).

---

## Trigger

Run with `/passive-status` or "show passive rules".

---

## Process

1. Read `~/.claude/skills/_passive-rules.json`
2. For each rule, check usage stats
3. Sort by fire count descending
4. Display dashboard

---

## Dashboard Format

```
PASSIVE RULES STATUS

  Active rules: 6
  Total fires this month: 127
  Token overhead: ~800 tokens/session

  MOST ACTIVE
  ───────────
  #  Rule                        Fires  Last Fired   Domain
  1. conventional-commits           47   today        workflow
  2. validate-env-before-deploy     28   2 days ago   deployment
  3. typescript-strict-mode         23   today        development
  4. add-timestamps-to-tables       18   1 week ago   development

  MODERATE
  ────────
  5. check-rls-on-supabase          11   2 weeks ago  security

  NEVER FIRED
  ───────────
  6. legacy-migration-warn           0   never        deployment
     Reason: Trigger condition may be too specific
     [R] Remove  [E] Edit trigger  [K] Keep

  SUMMARY
  ───────
  Avg fires/rule: 21.2
  Most valuable:  "conventional-commits" (47 fires, saves ~5 sec each)
  Least valuable: "legacy-migration-warn" (0 fires)

  Actions:
  [N] New rule  [E] Edit a rule  [R] Remove a rule  [X] Close
```

---

## Rule Format Reference

Each passive rule in `_passive-rules.json`:

```json
{
  "id": "rule_001",
  "name": "conventional-commits",
  "trigger": "When creating a git commit message",
  "action": "Format as conventional commit: type(scope): description",
  "domain": "workflow",
  "enabled": true,
  "fireCount": 47,
  "lastFired": "2025-02-20T14:30:00Z",
  "createdFrom": "inst_g003",
  "createdDate": "2025-01-15"
}
```
