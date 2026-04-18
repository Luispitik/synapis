#!/bin/bash
# test-seeds.sh — TDD Unit Tests for Sinapsis seed importer
# Covers: YAML parsing, confidence→level mapping, idempotency, dedupe, CLI flags.
# Run: bash tests/test-seeds.sh

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMPORTER="$SCRIPT_DIR/core/_seed-import.py"
SEEDS_REPO="$SCRIPT_DIR/seeds/instincts"

PASS=0
FAIL=0
TOTAL=8

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; }

setup_sandbox() {
  SANDBOX="$(mktemp -d 2>/dev/null || mktemp -d -t sinapsis-seeds)"
  mkdir -p "$SANDBOX/skills"
  # Windows/Git-Bash: convert POSIX path to native so Python can open it
  if command -v cygpath >/dev/null 2>&1; then
    SANDBOX_NATIVE="$(cygpath -m "$SANDBOX")"
    SEEDS_NATIVE="$(cygpath -m "$SEEDS_REPO")"
  else
    SANDBOX_NATIVE="$SANDBOX"
    SEEDS_NATIVE="$SEEDS_REPO"
  fi
  INDEX_PATH="$SANDBOX_NATIVE/skills/_instincts-index.json"
  cat > "$INDEX_PATH" <<'EOF'
{
  "version": "4.2",
  "description": "test",
  "levels": {},
  "domainDedup": [],
  "instincts": []
}
EOF
}

teardown_sandbox() {
  rm -rf "$SANDBOX" 2>/dev/null
}

count_instincts() {
  python -c "import json,sys; d=json.load(open(r'$1')); print(len(d.get('instincts',[])))"
}

get_level() {
  python -c "import json,sys; d=json.load(open(r'$1')); m={i['id']:i['level'] for i in d.get('instincts',[])}; print(m.get('$2','MISSING'))"
}

count_by_origin_prefix() {
  python -c "import json,sys; d=json.load(open(r'$1')); print(sum(1 for i in d.get('instincts',[]) if i.get('origin','').startswith('$2')))"
}

# ─ Test 1: importer exists and is executable via python ─
echo "Test 1: importer exists"
if [ -f "$IMPORTER" ]; then pass "importer file present"; else fail "importer missing: $IMPORTER"; fi

# ─ Test 2: seeds directory exists with YAMLs ─
echo "Test 2: seeds directory populated"
SEED_COUNT=$(find "$SEEDS_REPO" -name "*.yaml" -type f 2>/dev/null | wc -l)
if [ "$SEED_COUNT" -gt 0 ]; then pass "$SEED_COUNT seed YAMLs found"; else fail "no seeds found in $SEEDS_REPO"; fi

# ─ Test 3: fresh import produces N instincts ─
echo "Test 3: fresh import"
setup_sandbox
python "$IMPORTER" --seeds-dir "$SEEDS_NATIVE" --index-path "$INDEX_PATH" > /dev/null 2>&1
COUNT=$(count_instincts "$INDEX_PATH")
if [ "$COUNT" = "$SEED_COUNT" ]; then pass "imported $COUNT instincts"; else fail "expected $SEED_COUNT, got $COUNT"; fi

# ─ Test 4: idempotency — second run adds 0 ─
echo "Test 4: idempotency"
python "$IMPORTER" --seeds-dir "$SEEDS_NATIVE" --index-path "$INDEX_PATH" > /dev/null 2>&1
COUNT2=$(count_instincts "$INDEX_PATH")
if [ "$COUNT2" = "$COUNT" ]; then pass "second run unchanged"; else fail "idempotency broken: $COUNT → $COUNT2"; fi

# ─ Test 5: origin field is prefixed with seed: ─
echo "Test 5: origin prefix"
SEEDED=$(count_by_origin_prefix "$INDEX_PATH" "seed")
if [ "$SEEDED" = "$SEED_COUNT" ]; then pass "all $SEEDED instincts have origin starting 'seed'"; else fail "origin prefix mismatch: $SEEDED/$SEED_COUNT"; fi

# ─ Test 6: confidence ≥0.90 → permanent ─
echo "Test 6: confidence→permanent mapping"
# conventional-commits has confidence 0.90 in the ship seeds
LVL=$(get_level "$INDEX_PATH" "conventional-commits")
if [ "$LVL" = "permanent" ]; then pass "conventional-commits mapped to permanent"; else fail "expected permanent, got: $LVL"; fi

# ─ Test 7: --skip flag excludes ID ─
echo "Test 7: --skip flag"
teardown_sandbox; setup_sandbox
python "$IMPORTER" --seeds-dir "$SEEDS_NATIVE" --index-path "$INDEX_PATH" --skip conventional-commits > /dev/null 2>&1
LVL_SKIP=$(get_level "$INDEX_PATH" "conventional-commits")
if [ "$LVL_SKIP" = "MISSING" ]; then pass "--skip excluded conventional-commits"; else fail "--skip did not exclude: $LVL_SKIP"; fi

# ─ Test 8: --force-draft overrides level ─
echo "Test 8: --force-draft flag"
teardown_sandbox; setup_sandbox
python "$IMPORTER" --seeds-dir "$SEEDS_NATIVE" --index-path "$INDEX_PATH" --force-draft supabase-rls-auth-uid > /dev/null 2>&1
LVL_FD=$(get_level "$INDEX_PATH" "supabase-rls-auth-uid")
if [ "$LVL_FD" = "draft" ]; then pass "supabase-rls-auth-uid forced to draft"; else fail "expected draft, got: $LVL_FD"; fi

teardown_sandbox

echo ""
echo "────────────────────────────"
echo "Results: $PASS/$TOTAL passed, $FAIL failed"
echo "────────────────────────────"
[ "$FAIL" -eq 0 ]
