#!/bin/bash
# test-reflexes.sh — TDD Unit Tests for Sinapsis reflex merger (v4.5)
# Covers: shipped seed structure, idempotency, user customizations preserved,
#         activator integration (rules actually fire), dedupe on re-run.
# Run: bash tests/test-reflexes.sh

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MERGER="$SCRIPT_DIR/core/_reflex-merge.mjs"
SEEDS_FILE="$SCRIPT_DIR/seeds/reflexes.json"
ACTIVATOR="$SCRIPT_DIR/core/_passive-activator.sh"

# Normalize paths for native tools (Node on Windows Git Bash expects C:/... not /c/...)
if command -v cygpath >/dev/null 2>&1; then
  SEEDS_NATIVE_GLOBAL="$(cygpath -m "$SEEDS_FILE")"
else
  SEEDS_NATIVE_GLOBAL="$SEEDS_FILE"
fi

PASS=0
FAIL=0
TOTAL=10

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

setup_sandbox() {
  SANDBOX="$(mktemp -d 2>/dev/null || mktemp -d -t sinapsis-reflexes)"
  mkdir -p "$SANDBOX/.claude/skills"
  export HOME="$SANDBOX"
  # Install a minimal user index with 1 existing rule to simulate upgrade path
  cat > "$SANDBOX/.claude/skills/_passive-rules.json" <<'EOF'
{
  "version": "4.1",
  "system": "sinapsis",
  "description": "test",
  "rules": [
    {
      "id": "user-custom-rule",
      "trigger": "custom_pattern",
      "inject": "User custom rule",
      "severity": "medium",
      "category": "workflow",
      "tokens": 15
    }
  ],
  "totalTokens": 15
}
EOF
  if command -v cygpath >/dev/null 2>&1; then
    INDEX_NATIVE="$(cygpath -m "$SANDBOX/.claude/skills/_passive-rules.json")"
    SEEDS_NATIVE="$(cygpath -m "$SEEDS_FILE")"
    MERGER_NATIVE="$(cygpath -m "$MERGER")"
    ACTIVATOR_NATIVE="$(cygpath -m "$ACTIVATOR")"
  else
    INDEX_NATIVE="$SANDBOX/.claude/skills/_passive-rules.json"
    SEEDS_NATIVE="$SEEDS_FILE"
    MERGER_NATIVE="$MERGER"
    ACTIVATOR_NATIVE="$ACTIVATOR"
  fi
}

teardown_sandbox() {
  unset HOME
  rm -rf "$SANDBOX" 2>/dev/null
}

count_rules() {
  node -e "const r=JSON.parse(require('fs').readFileSync('$1','utf8')); console.log((r.rules||[]).length)"
}

has_rule() {
  node -e "const r=JSON.parse(require('fs').readFileSync('$1','utf8')); console.log((r.rules||[]).some(x => x.id === '$2') ? 'yes' : 'no')"
}

# ─ Test 1: merger + seeds files present ─
echo "Test 1: artifact presence"
if [ -f "$MERGER" ] && [ -f "$SEEDS_FILE" ]; then
  pass "merger + seeds file present"
else
  fail "missing: MERGER=$MERGER SEEDS=$SEEDS_FILE"
fi

# ─ Test 2: seeds file is valid JSON with >= 5 rules ─
echo "Test 2: seeds file structure"
SEED_COUNT=$(node -e "const r=JSON.parse(require('fs').readFileSync('$SEEDS_NATIVE_GLOBAL','utf8')); console.log((r.rules||[]).length)" 2>/dev/null)
if [ -n "$SEED_COUNT" ] && [ "$SEED_COUNT" -ge 5 ]; then
  pass "$SEED_COUNT seed rules found"
else
  fail "expected >=5 seed rules, got '$SEED_COUNT'"
fi

# ─ Test 3: fresh merge adds all seed rules ─
echo "Test 3: fresh merge"
setup_sandbox
node "$MERGER_NATIVE" --seeds-path "$SEEDS_NATIVE" --index-path "$INDEX_NATIVE" > /dev/null 2>&1
COUNT=$(count_rules "$INDEX_NATIVE")
EXPECTED=$((1 + SEED_COUNT))
if [ "$COUNT" = "$EXPECTED" ]; then
  pass "merged $SEED_COUNT seeds into 1 existing = $COUNT total"
else
  fail "expected $EXPECTED, got $COUNT"
fi
teardown_sandbox

# ─ Test 4: idempotency — second run adds nothing ─
echo "Test 4: idempotency"
setup_sandbox
node "$MERGER_NATIVE" --seeds-path "$SEEDS_NATIVE" --index-path "$INDEX_NATIVE" > /dev/null 2>&1
C1=$(count_rules "$INDEX_NATIVE")
node "$MERGER_NATIVE" --seeds-path "$SEEDS_NATIVE" --index-path "$INDEX_NATIVE" > /dev/null 2>&1
C2=$(count_rules "$INDEX_NATIVE")
if [ "$C1" = "$C2" ]; then
  pass "second run unchanged ($C2 rules)"
else
  fail "idempotency broken: $C1 -> $C2"
fi
teardown_sandbox

# ─ Test 5: user customizations preserved ─
echo "Test 5: user custom rule preserved"
setup_sandbox
node "$MERGER_NATIVE" --seeds-path "$SEEDS_NATIVE" --index-path "$INDEX_NATIVE" > /dev/null 2>&1
HAS=$(has_rule "$INDEX_NATIVE" "user-custom-rule")
if [ "$HAS" = "yes" ]; then
  pass "user-custom-rule still present after merge"
else
  fail "user-custom-rule lost during merge"
fi
teardown_sandbox

# ─ Test 6: conflict resolution — existing id wins over seed ─
echo "Test 6: conflict — user rule wins"
setup_sandbox
# Override the user index with a rule id matching a seed id
cat > "$INDEX_NATIVE" <<'EOF'
{
  "version": "4.1",
  "system": "sinapsis",
  "description": "test",
  "rules": [
    {
      "id": "read-before-edit",
      "trigger": "CUSTOM_OVERRIDE",
      "inject": "user override",
      "severity": "low",
      "category": "workflow",
      "tokens": 10
    }
  ],
  "totalTokens": 10
}
EOF
node "$MERGER_NATIVE" --seeds-path "$SEEDS_NATIVE" --index-path "$INDEX_NATIVE" > /dev/null 2>&1
TRIG=$(node -e "const r=JSON.parse(require('fs').readFileSync('$INDEX_NATIVE','utf8')); console.log(r.rules.find(x => x.id === 'read-before-edit').trigger)")
if [ "$TRIG" = "CUSTOM_OVERRIDE" ]; then
  pass "user override preserved (seed did not overwrite)"
else
  fail "user override lost — got trigger: $TRIG"
fi
teardown_sandbox

# ─ Test 7: totalTokens recomputed ─
echo "Test 7: totalTokens recomputed after merge"
setup_sandbox
node "$MERGER_NATIVE" --seeds-path "$SEEDS_NATIVE" --index-path "$INDEX_NATIVE" > /dev/null 2>&1
TT=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$INDEX_NATIVE','utf8')).totalTokens)")
# Expected: 15 (user rule) + sum of seed tokens
EXPECTED_TT=$(node -e "const s=JSON.parse(require('fs').readFileSync('$SEEDS_NATIVE','utf8')); console.log(15 + s.rules.reduce((a,r) => a + (r.tokens||0), 0))")
if [ "$TT" = "$EXPECTED_TT" ]; then
  pass "totalTokens = $TT (expected $EXPECTED_TT)"
else
  fail "totalTokens mismatch: got $TT, expected $EXPECTED_TT"
fi
teardown_sandbox

# ─ Test 8: activator integration — read-before-edit fires on Edit ─
echo "Test 8: activator fires read-before-edit on Edit"
setup_sandbox
node "$MERGER_NATIVE" --seeds-path "$SEEDS_NATIVE" --index-path "$INDEX_NATIVE" > /dev/null 2>&1
PAYLOAD=$(node -e 'process.stdout.write(JSON.stringify({tool_name:"Edit",tool_input:{file_path:"foo.ts"}}))')
OUT=$(echo "$PAYLOAD" | bash "$ACTIVATOR_NATIVE" 2>/dev/null)
if echo "$OUT" | grep -q "Before editing"; then
  pass "read-before-edit fired on Edit"
else
  fail "read-before-edit did not fire. Got: $OUT"
fi
teardown_sandbox

# ─ Test 9: activator integration — git-push-safety fires on git push ─
echo "Test 9: activator fires git-push-safety on git push"
setup_sandbox
node "$MERGER_NATIVE" --seeds-path "$SEEDS_NATIVE" --index-path "$INDEX_NATIVE" > /dev/null 2>&1
PAYLOAD=$(node -e 'process.stdout.write(JSON.stringify({tool_name:"Bash",tool_input:{command:"git push origin main"}}))')
OUT=$(echo "$PAYLOAD" | bash "$ACTIVATOR_NATIVE" 2>/dev/null)
if echo "$OUT" | grep -q "fetch + rebase"; then
  pass "git-push-safety fired"
else
  fail "git-push-safety did not fire. Got: $OUT"
fi
teardown_sandbox

# ─ Test 10: --dry-run writes nothing ─
echo "Test 10: --dry-run"
setup_sandbox
BEFORE=$(count_rules "$INDEX_NATIVE")
node "$MERGER_NATIVE" --seeds-path "$SEEDS_NATIVE" --index-path "$INDEX_NATIVE" --dry-run > /dev/null 2>&1
AFTER=$(count_rules "$INDEX_NATIVE")
if [ "$BEFORE" = "$AFTER" ]; then
  pass "--dry-run did not modify index"
else
  fail "--dry-run modified index: $BEFORE -> $AFTER"
fi
teardown_sandbox

# ─ Test 11: test-after-change does NOT fire on Read/Grep (Codex scope fix) ─
echo "Test 11: test-after-change scoped to Edit/Write only"
setup_sandbox
node "$MERGER_NATIVE" --seeds-path "$SEEDS_NATIVE" --index-path "$INDEX_NATIVE" > /dev/null 2>&1
READ_PAYLOAD=$(node -e 'process.stdout.write(JSON.stringify({tool_name:"Read",tool_input:{file_path:"auth.test.ts"}}))')
READ_OUT=$(echo "$READ_PAYLOAD" | bash "$ACTIVATOR_NATIVE" 2>/dev/null)
if ! echo "$READ_OUT" | grep -q "Code modified"; then
  pass "test-after-change did NOT fire on Read"
else
  fail "test-after-change fired on Read (false positive): $READ_OUT"
fi
teardown_sandbox

TOTAL=11

echo ""
echo "═══════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed (of $TOTAL)"
echo "═══════════════════════════════════════"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
