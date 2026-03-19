#!/bin/bash
#
# Tests for loop auto-resume feature
#
# Tests cover:
# - --probe outputs CLEAR when no active loop
# - --probe outputs RESUME_PROMPT when active loop exists
# - --do-resume outputs resume banner with correct round number
# - --do-resume outputs round prompt file content when it exists
# - --do-resume outputs fallback prompt when round prompt file is missing
# - --do-resume writes .pending-session-id with force=true on line 3
# - --do-resume does NOT clear session_id in state.md before hook fires
# - hook: patches non-empty session_id when force=true
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Source shared loop library
HOOKS_LIB_DIR="$(cd "$SCRIPT_DIR/../hooks/lib" && pwd)"
source "$HOOKS_LIB_DIR/loop-common.sh"

SETUP_SCRIPT="$SCRIPT_DIR/../scripts/setup-rlcr-loop.sh"
POST_BASH_HOOK="$SCRIPT_DIR/../hooks/loop-post-bash-hook.sh"

echo "=========================================="
echo "Loop Resume Tests"
echo "=========================================="
echo ""

# ========================================
# Helper: create a loop dir with state.md
# Usage: make_loop_dir <loop_dir> <current_round> <plan_file>
# Creates: <loop_dir>/state.md
# ========================================

make_loop_dir() {
    local loop_dir="$1"
    local current_round="$2"
    local plan_file="$3"

    mkdir -p "$loop_dir"
    cat > "$loop_dir/state.md" << EOF
---
current_round: $current_round
max_iterations: 42
plan_file: $plan_file
base_branch: main
base_commit: abc123
session_id: old-session-abc
review_started: false
start_branch: main
---
EOF
}

# ========================================
# Group 1: --probe CLEAR (no active loop)
# ========================================

setup_test_dir
init_test_git_repo "$TEST_DIR/project"

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR/project" bash "$SETUP_SCRIPT" --probe temp/plan.md 2>/dev/null || true)
assert_equals "CLEAR" "$(printf '%s' "$OUTPUT" | head -1)" "--probe outputs CLEAR when no active loop"

CLAUDE_PROJECT_DIR="$TEST_DIR/project" bash "$SETUP_SCRIPT" --probe temp/plan.md > /dev/null 2>&1
ACTUAL_EXIT=$?
assert_exit_code "0" "$ACTUAL_EXIT" "--probe exits 0 on CLEAR"

# ========================================
# Group 2: --probe RESUME_PROMPT (active loop exists)
# ========================================

setup_test_dir
init_test_git_repo "$TEST_DIR/project"

LOOP_DIR="$TEST_DIR/project/.duo/rlcr/2026-01-01_00-00-00"
make_loop_dir "$LOOP_DIR" "3" "temp/plan.md"

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR/project" bash "$SETUP_SCRIPT" --probe temp/plan.md 2>/dev/null || true)
assert_equals "RESUME_PROMPT" "$(printf '%s' "$OUTPUT" | head -1)" "--probe outputs RESUME_PROMPT when loop exists"
assert_contains "$OUTPUT" "current_round: 3" "--probe includes current_round"
assert_contains "$OUTPUT" "loop_dir:" "--probe includes loop_dir field"

# Check exit code 4 for RESUME_PROMPT
CLAUDE_PROJECT_DIR="$TEST_DIR/project" bash "$SETUP_SCRIPT" --probe temp/plan.md > /dev/null 2>&1 || PROBE_EXIT=$?
PROBE_EXIT="${PROBE_EXIT:-0}"
assert_exit_code "4" "$PROBE_EXIT" "--probe exits 4 on RESUME_PROMPT"

# ========================================
# Group 3: --do-resume banner and prompt content
# ========================================

setup_test_dir
init_test_git_repo "$TEST_DIR/project"

LOOP_DIR="$TEST_DIR/project/.duo/rlcr/2026-01-01_00-00-00"
make_loop_dir "$LOOP_DIR" "5" "temp/plan.md"

# Write round-5-prompt.md so --do-resume finds it
cat > "$LOOP_DIR/round-5-prompt.md" << 'EOF'
# Round 5 Prompt

Continue implementing from round 5.
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR/project" bash "$SETUP_SCRIPT" --do-resume "$LOOP_DIR" 2>/dev/null || true)
assert_contains "$OUTPUT" "duo:run resumed (round 5)" "--do-resume shows round in banner"
assert_contains "$OUTPUT" "Round 5 Prompt" "--do-resume outputs round prompt file content"

# ========================================
# Group 4: --do-resume signal file contents
# (reuse the same setup as group 3 -- already ran --do-resume above)
# ========================================

SIGNAL_FILE="$TEST_DIR/project/.duo/.pending-session-id"
assert_file_exists "$SIGNAL_FILE" "--do-resume writes .pending-session-id signal file"

SIGNAL_LINE3=$(sed -n '3p' "$SIGNAL_FILE")
assert_equals "force=true" "$SIGNAL_LINE3" "--do-resume writes force=true on line 3"

SIGNAL_LINE1=$(head -1 "$SIGNAL_FILE")
assert_equals "$LOOP_DIR/state.md" "$SIGNAL_LINE1" "signal file line 1 points to state.md"

# --do-resume must NOT clear session_id in state.md before the hook fires
STORED_SESSION=$(grep "^session_id:" "$LOOP_DIR/state.md" | sed 's/session_id:[[:space:]]*//')
assert_equals "old-session-abc" "$STORED_SESSION" "--do-resume does NOT clear session_id before hook fires"

# ========================================
# Group 5: --do-resume fallback prompt (no round prompt file)
# ========================================

setup_test_dir
init_test_git_repo "$TEST_DIR/project"

LOOP_DIR="$TEST_DIR/project/.duo/rlcr/2026-01-01_00-00-00"
make_loop_dir "$LOOP_DIR" "3" "temp/plan.md"
# intentionally do NOT create round-3-prompt.md

OUTPUT=$(CLAUDE_PROJECT_DIR="$TEST_DIR/project" bash "$SETUP_SCRIPT" --do-resume "$LOOP_DIR" 2>/dev/null || true)
assert_contains "$OUTPUT" "duo:run resumed (round 3)" "--do-resume fallback shows banner"
assert_contains "$OUTPUT" "Resumed at Round 3" "--do-resume shows fallback prompt when no round prompt file"

# ========================================
# Group 6: hook patches non-empty session_id when force=true
# ========================================

setup_test_dir
init_test_git_repo "$TEST_DIR/project"

LOOP_DIR="$TEST_DIR/project/.duo/rlcr/2026-01-01_00-00-00"
make_loop_dir "$LOOP_DIR" "2" "temp/plan.md"
# state.md already has session_id: old-session-abc (set by make_loop_dir)

MOCK_SETUP="/mock/path/setup-rlcr-loop.sh"
mkdir -p "$TEST_DIR/project/.duo"
printf '%s\n%s\nforce=true\n' "$LOOP_DIR/state.md" "$MOCK_SETUP" > "$TEST_DIR/project/.duo/.pending-session-id"

HOOK_JSON="{\"session_id\": \"new-session-xyz\", \"tool_input\": {\"command\": \"${MOCK_SETUP} --do-resume /some/dir\"}}"
echo "$HOOK_JSON" | CLAUDE_PROJECT_DIR="$TEST_DIR/project" bash "$POST_BASH_HOOK" 2>/dev/null || true

PATCHED_SESSION=$(grep "^session_id:" "$LOOP_DIR/state.md" | sed 's/session_id:[[:space:]]*//')
assert_equals "new-session-xyz" "$PATCHED_SESSION" "hook replaces non-empty session_id when force=true"
assert_not_exists "$TEST_DIR/project/.duo/.pending-session-id" "signal file removed after hook fires"

# ========================================
# Print Summary
# ========================================

print_test_summary "Loop Resume Tests"
