#!/bin/bash
# Test /duo:help command file structure
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf '\033[0;32mPASS\033[0m: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '\033[0;31mFAIL\033[0m: %s\n' "$1"; }

HELP_FILE="$PROJECT_ROOT/commands/help.md"

# Test 1: File exists
if [[ -f "$HELP_FILE" ]]; then
    pass "help.md exists"
else
    fail "help.md does not exist"
fi

# Test 2: Has frontmatter
if head -1 "$HELP_FILE" | grep -q '^---'; then
    pass "has frontmatter"
else
    fail "missing frontmatter"
fi

# Test 3: Has description in frontmatter
if grep -q '^description:' "$HELP_FILE"; then
    pass "has description field"
else
    fail "missing description field"
fi

# Test 4: Lists all core commands
for cmd in "/duo:start" "/duo:run" "/duo:stop" "/duo:pr" "/duo:pr-stop" "/duo:ask" "/duo:setup" "/duo:help"; do
    if grep -q "$cmd" "$HELP_FILE"; then
        pass "lists $cmd"
    else
        fail "missing $cmd"
    fi
done

# Test 4b: Removed commands should not appear
for cmd in "/duo:plan" "/duo:draft"; do
    if grep -q "$cmd" "$HELP_FILE"; then
        fail "removed command $cmd still present"
    else
        pass "removed command $cmd not listed"
    fi
done

# Test 5: Mentions monitor
if grep -q "duo monitor" "$HELP_FILE"; then
    pass "mentions monitor command"
else
    fail "missing monitor command reference"
fi

# Test 6: Does not contain rlcr in user-facing text
if grep -v '^#' "$HELP_FILE" | grep -qi 'rlcr'; then
    fail "contains rlcr in user-facing text"
else
    pass "no rlcr in user-facing text"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
