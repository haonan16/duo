#!/bin/bash
# Test /duo:setup command and environment setup script
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

SETUP_SCRIPT="$PROJECT_ROOT/scripts/setup-environment.sh"
SETUP_CMD="$PROJECT_ROOT/commands/setup.md"

# --- setup-environment.sh tests ---

# Test 1: Script exists and is executable
if [[ -x "$SETUP_SCRIPT" ]]; then
    pass "setup-environment.sh exists and is executable"
else
    fail "setup-environment.sh missing or not executable"
fi

# Test 2: Script has --check-prereqs flag
if grep -q 'check-prereqs' "$SETUP_SCRIPT"; then
    pass "supports --check-prereqs flag"
else
    fail "missing --check-prereqs flag"
fi

# Test 3: Checks for codex
if grep -q 'codex' "$SETUP_SCRIPT"; then
    pass "checks for codex"
else
    fail "does not check for codex"
fi

# Test 4: Checks for jq
if grep -q 'jq' "$SETUP_SCRIPT"; then
    pass "checks for jq"
else
    fail "does not check for jq"
fi

# Test 5: Checks for git
if grep -q 'git' "$SETUP_SCRIPT"; then
    pass "checks for git"
else
    fail "does not check for git"
fi

# Test 6: Checks for gh
if grep -q '"gh"' "$SETUP_SCRIPT" || grep -q "'gh'" "$SETUP_SCRIPT" || grep -q 'command.*gh' "$SETUP_SCRIPT"; then
    pass "checks for gh"
else
    fail "does not check for gh"
fi

# Test 7: --check-prereqs runs without error
if "$SETUP_SCRIPT" --check-prereqs > "$TMPDIR/prereqs.txt" 2>&1; then
    pass "--check-prereqs runs successfully"
else
    # May fail if prereqs missing, but should not crash
    if [[ $? -le 1 ]]; then
        pass "--check-prereqs exits cleanly even with missing prereqs"
    else
        fail "--check-prereqs crashed"
    fi
fi

# Test 8: Output includes status for each prereq
PREREQ_OUTPUT="$(cat "$TMPDIR/prereqs.txt")"
for tool in codex jq git gh; do
    if echo "$PREREQ_OUTPUT" | grep -qi "$tool"; then
        pass "prereq output mentions $tool"
    else
        fail "prereq output missing $tool"
    fi
done

# --- scripts/setup.sh tests ---

# Test 12: Standalone setup script exists and is executable
STANDALONE_SETUP="$PROJECT_ROOT/scripts/setup.sh"
if [[ -x "$STANDALONE_SETUP" ]]; then
    pass "setup.sh exists and is executable"
else
    fail "setup.sh missing or not executable"
fi

# Test 13: Standalone script calls setup-environment.sh
if grep -q 'setup-environment.sh' "$STANDALONE_SETUP"; then
    pass "setup.sh calls setup-environment.sh"
else
    fail "setup.sh does not call setup-environment.sh"
fi

# Test 14: Standalone script has interactive prompts
if grep -q 'read -r' "$STANDALONE_SETUP"; then
    pass "setup.sh has interactive prompts"
else
    fail "setup.sh missing interactive prompts"
fi

# --- commands/setup.md tests ---

# Test 15: Command file exists
if [[ -f "$SETUP_CMD" ]]; then
    pass "setup.md exists"
else
    fail "setup.md does not exist"
fi

# Test 16: Has frontmatter
if head -1 "$SETUP_CMD" | grep -q '^---'; then
    pass "has frontmatter"
else
    fail "missing frontmatter"
fi

# Test 17: References setup-environment.sh
if grep -q 'setup-environment' "$SETUP_CMD"; then
    pass "references setup script"
else
    fail "missing reference to setup script"
fi

# Test 18: Mentions monitor setup
if grep -q 'monitor\|duo.sh' "$SETUP_CMD"; then
    pass "mentions monitor setup"
else
    fail "missing monitor setup instructions"
fi

teardown

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
