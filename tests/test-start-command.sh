#!/bin/bash
# Test /duo:start command and plan structure detection
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
TMPDIR=""

pass() { PASS=$((PASS + 1)); printf '\033[0;32mPASS\033[0m: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '\033[0;31mFAIL\033[0m: %s\n' "$1"; }

setup() {
    TMPDIR="$(mktemp -d)"
}

teardown() {
    [[ -n "$TMPDIR" ]] && rm -rf "$TMPDIR"
}

setup

DETECT="$PROJECT_ROOT/scripts/detect-plan-structure.sh"
START_FILE="$PROJECT_ROOT/commands/start.md"

# --- detect-plan-structure.sh tests ---

# Test 1: Script exists and is executable
if [[ -x "$DETECT" ]]; then
    pass "detect-plan-structure.sh exists and is executable"
else
    fail "detect-plan-structure.sh missing or not executable"
fi

# Test 2: Detects a valid plan (has Goal Description, AC, and Path Boundaries)
cat > "$TMPDIR/plan.md" << 'PLAN'
# My Plan

## Goal Description
Build a feature

## Acceptance Criteria
- AC-1: Feature works
  - Positive Tests: it works
  - Negative Tests: it fails gracefully

## Path Boundaries

### Upper Bound
Full implementation

### Lower Bound
Minimal implementation
PLAN

if "$DETECT" "$TMPDIR/plan.md" 2>/dev/null; then
    pass "detects valid plan structure"
else
    fail "should detect valid plan structure"
fi

# Test 3: Rejects a draft (no plan sections)
cat > "$TMPDIR/draft.md" << 'DRAFT'
# Ideas

I want to build a feature that does X and Y.
It should be fast and reliable.
DRAFT

if "$DETECT" "$TMPDIR/draft.md" 2>/dev/null; then
    fail "should reject draft (no plan structure)"
else
    pass "rejects draft without plan structure"
fi

# Test 4: Rejects empty file
touch "$TMPDIR/empty.md"
if "$DETECT" "$TMPDIR/empty.md" 2>/dev/null; then
    fail "should reject empty file"
else
    pass "rejects empty file"
fi

# Test 5: Rejects nonexistent file
if "$DETECT" "$TMPDIR/nonexistent.md" 2>/dev/null; then
    fail "should reject nonexistent file"
else
    pass "rejects nonexistent file"
fi

# Test 6: Rejects file with AC but missing Goal Description and Path Boundaries
cat > "$TMPDIR/partial-plan.md" << 'PLAN'
# Partial Plan

## Acceptance Criteria
- AC-1: Something
PLAN

if "$DETECT" "$TMPDIR/partial-plan.md" 2>/dev/null; then
    fail "should reject plan missing Goal Description and Path Boundaries"
else
    pass "rejects partial plan (AC only, missing required sections)"
fi

# Test 7: Rejects file with Goal Description and AC but missing Path Boundaries
cat > "$TMPDIR/no-boundaries.md" << 'PLAN'
# Almost Plan

## Goal Description
Build something

## Acceptance Criteria
- AC-1: Something
PLAN

if "$DETECT" "$TMPDIR/no-boundaries.md" 2>/dev/null; then
    fail "should reject plan missing Path Boundaries"
else
    pass "rejects plan without Path Boundaries"
fi

# --- commands/start.md tests ---

# Test 8: Command file exists
if [[ -f "$START_FILE" ]]; then
    pass "start.md exists"
else
    fail "start.md does not exist"
fi

# Test 9: Has frontmatter with description
if grep -q '^description:' "$START_FILE"; then
    pass "has description field"
else
    fail "missing description field"
fi

# Test 10: References detect-plan-structure.sh
if grep -q 'detect-plan-structure' "$START_FILE"; then
    pass "references detection script"
else
    fail "missing reference to detection script"
fi

# Test 11: References setup-rlcr-loop.sh for running plans
if grep -q 'setup-rlcr-loop' "$START_FILE"; then
    pass "references setup-rlcr-loop.sh"
else
    fail "missing reference to setup-rlcr-loop.sh"
fi

# Test 12: References validate-gen-plan-io.sh for drafts
if grep -q 'validate-gen-plan-io' "$START_FILE"; then
    pass "references validate-gen-plan-io.sh"
else
    fail "missing reference to validate-gen-plan-io.sh"
fi

# Test 13: Supports --plan-only flag (and --draft-only backward compat alias)
if grep -q 'plan-only' "$START_FILE" && grep -q 'draft-only' "$START_FILE"; then
    pass "supports --plan-only flag (with --draft-only alias)"
else
    fail "missing --plan-only or --draft-only flag support"
fi

# Test 14: Supports --review-only flag
if grep -q 'review-only' "$START_FILE"; then
    pass "supports --review-only flag"
else
    fail "missing --review-only flag support"
fi

# Test 15: Does not contain rlcr in user-facing text (exclude allowed-tools, script refs, and on-disk paths)
if grep -v '^allowed-tools\|scripts/\|setup-rlcr\|cancel-rlcr\|rlcr-stop\|\.duo/rlcr' "$START_FILE" | grep -v '^\s*-\s*"Bash' | grep -qi 'rlcr'; then
    fail "contains rlcr in user-facing text"
else
    pass "no rlcr in user-facing text"
fi

teardown

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
