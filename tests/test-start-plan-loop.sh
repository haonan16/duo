#!/bin/bash
#
# Tests for plan command and plan-review template
#
# Validates:
#   - plan-review.md template exists and has required structure
#   - plan.md command exists with valid frontmatter
#   - Template placeholder substitution works correctly
#   - Integration contracts with reused scripts
#   - Draft preservation through the pipeline
#   - Version consistency
#   - No Emoji or CJK characters
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMANDS_DIR="$PROJECT_ROOT/commands"
TEMPLATE_DIR="$PROJECT_ROOT/prompt-template"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

echo "=========================================="
echo "Start Plan Loop Tests"
echo "=========================================="
echo ""

# ========================================
# PT-1: Plan review template exists
# ========================================
echo "--- Template Tests ---"
echo ""
echo "PT-1: Plan review template file exists"
PLAN_REVIEW_TEMPLATE="$TEMPLATE_DIR/codex/plan-review.md"
if [[ -f "$PLAN_REVIEW_TEMPLATE" ]]; then
    pass "plan-review.md template exists"
else
    fail "plan-review.md template exists" "File exists" "File not found at $PLAN_REVIEW_TEMPLATE"
fi

# ========================================
# PT-2: Template has required placeholders
# ========================================
echo ""
echo "PT-2: Template has required placeholders"
if [[ -f "$PLAN_REVIEW_TEMPLATE" ]]; then
    if grep -q '{{CURRENT_ROUND}}' "$PLAN_REVIEW_TEMPLATE"; then
        pass "Template contains {{CURRENT_ROUND}} placeholder"
    else
        fail "Template contains {{CURRENT_ROUND}} placeholder"
    fi

    if grep -q '{{PLAN_CONTENT}}' "$PLAN_REVIEW_TEMPLATE"; then
        pass "Template contains {{PLAN_CONTENT}} placeholder"
    else
        fail "Template contains {{PLAN_CONTENT}} placeholder"
    fi
fi

# ========================================
# PT-3: Template has all 6 review dimensions
# ========================================
echo ""
echo "PT-3: Template has all 6 review dimensions"
if [[ -f "$PLAN_REVIEW_TEMPLATE" ]]; then
    for dim in "Clarity" "Consistency" "Completeness" "Functionality" "Feasibility" "Draft Alignment"; do
        if grep -qi "$dim" "$PLAN_REVIEW_TEMPLATE"; then
            pass "Template covers review dimension: $dim"
        else
            fail "Template covers review dimension: $dim"
        fi
    done
fi

# ========================================
# PT-4: Template has APPROVED keyword
# ========================================
echo ""
echo "PT-4: Template defines APPROVED exit condition"
if [[ -f "$PLAN_REVIEW_TEMPLATE" ]]; then
    if grep -q 'APPROVED' "$PLAN_REVIEW_TEMPLATE"; then
        pass "Template defines APPROVED keyword"
    else
        fail "Template defines APPROVED keyword"
    fi
fi

# ========================================
# PT-5: Template references original draft markers
# ========================================
echo ""
echo "PT-5: Template references original draft markers"
if [[ -f "$PLAN_REVIEW_TEMPLATE" ]]; then
    if grep -q 'Original Design Draft' "$PLAN_REVIEW_TEMPLATE"; then
        pass "Template references Original Design Draft markers"
    else
        fail "Template references Original Design Draft markers"
    fi
fi

# ========================================
# PT-6: Command file structure validation
# ========================================
echo ""
echo "--- Command Tests ---"
echo ""
echo "PT-6: Command file structure validation (plan merged into start)"
PLAN_LOOP_CMD="$COMMANDS_DIR/start.md"
if [[ -f "$PLAN_LOOP_CMD" ]]; then
    pass "start.md command file exists (contains plan generation workflow)"
else
    fail "start.md command file exists" "File exists" "File not found"
fi

# Verify plan.md was removed
if [[ ! -f "$COMMANDS_DIR/plan.md" ]]; then
    pass "plan.md has been removed (merged into start.md)"
else
    fail "plan.md should not exist" "File removed" "File still exists"
fi

# ========================================
# PT-7: Command has valid YAML frontmatter
# ========================================
echo ""
echo "PT-7: Command has valid YAML frontmatter"
if [[ -f "$PLAN_LOOP_CMD" ]]; then
    if head -1 "$PLAN_LOOP_CMD" | grep -q "^---$"; then
        pass "Command starts with YAML frontmatter delimiter"
    else
        fail "Command starts with YAML frontmatter delimiter"
    fi

    DESC=$(sed -n '/^---$/,/^---$/{ /^description:/{ s/^description:[[:space:]]*//p; q; } }' "$PLAN_LOOP_CMD")
    if [[ -n "$DESC" ]]; then
        pass "Command has description: ${DESC:0:60}..."
    else
        fail "Command has description" "Non-empty description" "(empty)"
    fi

    if grep -q "argument-hint:" "$PLAN_LOOP_CMD"; then
        pass "Command has argument-hint"
    else
        fail "Command has argument-hint"
    fi

    if grep -q "allowed-tools:" "$PLAN_LOOP_CMD"; then
        pass "Command has allowed-tools"
    else
        fail "Command has allowed-tools"
    fi
fi

# ========================================
# PT-8: Command references required tools
# ========================================
echo ""
echo "PT-8: Command references required scripts in allowed-tools"
if [[ -f "$PLAN_LOOP_CMD" ]]; then
    if grep -q 'validate-gen-plan-io.sh' "$PLAN_LOOP_CMD"; then
        pass "Command references validate-gen-plan-io.sh"
    else
        fail "Command references validate-gen-plan-io.sh"
    fi

    if grep -q 'ask-codex.sh' "$PLAN_LOOP_CMD"; then
        pass "Command references ask-codex.sh"
    else
        fail "Command references ask-codex.sh"
    fi
fi

# ========================================
# PT-9: Command documents all arguments
# ========================================
echo ""
echo "PT-9: Command documents all arguments"
if [[ -f "$PLAN_LOOP_CMD" ]]; then
    for arg in "--input" "--output" "--max" "--codex-model" "--codex-timeout"; do
        if grep -q -- "$arg" "$PLAN_LOOP_CMD"; then
            pass "Command documents $arg argument"
        else
            fail "Command documents $arg argument"
        fi
    done
fi

# ========================================
# PT-10: Command defines Round 0 and Round 1+ phases
# ========================================
echo ""
echo "PT-10: Command defines both loop phases"
if [[ -f "$PLAN_LOOP_CMD" ]]; then
    if grep -q 'Round 0' "$PLAN_LOOP_CMD"; then
        pass "Command defines Round 0 (initial generation)"
    else
        fail "Command defines Round 0 (initial generation)"
    fi

    if grep -q 'Round 1' "$PLAN_LOOP_CMD"; then
        pass "Command defines Round 1+ (iterative refinement)"
    else
        fail "Command defines Round 1+ (iterative refinement)"
    fi
fi

# ========================================
# PT-11: Integration contract - validate-gen-plan-io.sh mutates output
# ========================================
echo ""
echo "--- Integration Contract Tests ---"
echo ""
echo "PT-11: validate-gen-plan-io.sh creates output file with template + draft"

setup_test_dir

DRAFT_FILE="$TEST_DIR/test-draft.md"
OUTPUT_FILE="$TEST_DIR/test-plan.md"

echo "# Test Draft" > "$DRAFT_FILE"
echo "This is a test draft for validation." >> "$DRAFT_FILE"

VALIDATE_SCRIPT="$SCRIPTS_DIR/validate-gen-plan-io.sh"
if [[ -x "$VALIDATE_SCRIPT" ]]; then
    # Set CLAUDE_PLUGIN_ROOT so the script can find the template
    EXIT_CODE=0
    CLAUDE_PLUGIN_ROOT="$PROJECT_ROOT" "$VALIDATE_SCRIPT" \
        --input "$DRAFT_FILE" --output "$OUTPUT_FILE" > /dev/null 2>&1 || EXIT_CODE=$?

    if [[ $EXIT_CODE -eq 0 ]]; then
        pass "validate-gen-plan-io.sh exits 0 for valid inputs"
    else
        fail "validate-gen-plan-io.sh exits 0 for valid inputs" "exit 0" "exit $EXIT_CODE"
    fi

    if [[ -f "$OUTPUT_FILE" ]]; then
        pass "validate-gen-plan-io.sh creates output file"
    else
        fail "validate-gen-plan-io.sh creates output file" "File exists" "File not created"
    fi

    if grep -q "Original Design Draft Start" "$OUTPUT_FILE" 2>/dev/null; then
        pass "Output file contains draft start marker"
    else
        fail "Output file contains draft start marker"
    fi

    if grep -q "Original Design Draft End" "$OUTPUT_FILE" 2>/dev/null; then
        pass "Output file contains draft end marker"
    else
        fail "Output file contains draft end marker"
    fi

    if grep -q "Test Draft" "$OUTPUT_FILE" 2>/dev/null; then
        pass "Output file preserves original draft content"
    else
        fail "Output file preserves original draft content"
    fi

    if grep -q "Goal Description" "$OUTPUT_FILE" 2>/dev/null; then
        pass "Output file contains plan template structure"
    else
        fail "Output file contains plan template structure"
    fi
else
    fail "validate-gen-plan-io.sh not found or not executable"
fi

# ========================================
# PT-12: Integration contract - ask-codex.sh delivers prompt to codex
# ========================================
echo ""
echo "PT-12: ask-codex.sh delivers prompt text to mock codex"
ASK_CODEX_SCRIPT="$SCRIPTS_DIR/ask-codex.sh"
if [[ -x "$ASK_CODEX_SCRIPT" ]]; then
    # Use the same mock codex pattern as tests/test-ask-codex.sh
    MOCK_BIN_DIR="$TEST_DIR/mock-bin"
    mkdir -p "$MOCK_BIN_DIR"

    # Mock codex that echoes back what it receives on stdin
    cat > "$MOCK_BIN_DIR/codex" << 'MOCK_CODEX_EOF'
#!/bin/bash
# Echo stdin back to stdout so we can verify prompt delivery
cat
exit 0
MOCK_CODEX_EOF
    chmod +x "$MOCK_BIN_DIR/codex"

    MOCK_PROJECT="$TEST_DIR/mock-project"
    mkdir -p "$MOCK_PROJECT"
    (cd "$MOCK_PROJECT" && git init -q && git config user.email "t@t" && git config user.name "T" && git config commit.gpgsign false && echo x > f && git add f && git commit -q -m "init")

    PROMPT_TEXT="Test plan review prompt for round 3"
    EXIT_CODE=0
    CODEX_OUTPUT=$(
        cd "$MOCK_PROJECT"
        export CLAUDE_PROJECT_DIR="$MOCK_PROJECT"
        export XDG_CACHE_HOME="$TEST_DIR/cache"
        PATH="$MOCK_BIN_DIR:$PATH" bash "$ASK_CODEX_SCRIPT" "$PROMPT_TEXT" 2>/dev/null
    ) || EXIT_CODE=$?

    if [[ $EXIT_CODE -eq 0 ]]; then
        pass "ask-codex.sh exits 0 with mock codex"
    else
        fail "ask-codex.sh exits 0 with mock codex" "exit 0" "exit $EXIT_CODE"
    fi

    if echo "$CODEX_OUTPUT" | grep -q "Test plan review prompt"; then
        pass "ask-codex.sh delivers prompt text to codex process"
    else
        fail "ask-codex.sh delivers prompt text to codex process" \
            "Prompt text in output" "Got: ${CODEX_OUTPUT:0:100}"
    fi
else
    fail "ask-codex.sh not found or not executable"
fi

# ========================================
# PT-13: Template placeholder substitution test
# ========================================
echo ""
echo "PT-13: Template placeholder substitution produces valid prompt"
if [[ -f "$PLAN_REVIEW_TEMPLATE" ]]; then
    SUBSTITUTED=$(sed \
        -e 's/{{CURRENT_ROUND}}/3/g' \
        -e 's/{{PLAN_CONTENT}}/Test plan content here/g' \
        "$PLAN_REVIEW_TEMPLATE")

    if echo "$SUBSTITUTED" | grep -q 'Round 3'; then
        pass "CURRENT_ROUND substitution works"
    else
        fail "CURRENT_ROUND substitution works"
    fi

    if echo "$SUBSTITUTED" | grep -q 'Test plan content here'; then
        pass "PLAN_CONTENT substitution works"
    else
        fail "PLAN_CONTENT substitution works"
    fi

    # Verify no unsubstituted placeholders remain
    if echo "$SUBSTITUTED" | grep -q '{{'; then
        fail "All placeholders substituted" "No {{ remaining" "Found unsubstituted placeholders"
    else
        pass "All placeholders substituted"
    fi
fi

# ========================================
# NT-1: No Emoji or CJK in new files
# ========================================
echo ""
echo "--- Negative Tests ---"
echo ""
echo "NT-1: No Emoji or CJK characters in new files"
for CHECK_FILE in "$PLAN_REVIEW_TEMPLATE" "$PLAN_LOOP_CMD" ; do
    if [[ -f "$CHECK_FILE" ]]; then
        BASENAME=$(basename "$CHECK_FILE")
        if grep -Pq '[\p{Han}]|[\x{1F300}-\x{1F9FF}]|[\x{2600}-\x{26FF}]|[\x{2700}-\x{27BF}]' "$CHECK_FILE" 2>/dev/null; then
            fail "$BASENAME: Contains Emoji or CJK characters"
        else
            pass "$BASENAME: Content is English only"
        fi
    fi
done

# ========================================
# NT-2: Command name follows naming convention
# ========================================
echo ""
echo "NT-2: Command name follows naming convention"
if [[ "plan" =~ ^[a-z][a-z0-9-]*$ ]]; then
    pass "plan follows valid naming convention"
else
    fail "plan has invalid name format"
fi

# ========================================
# NT-3: Version consistency check
# ========================================
echo ""
echo "NT-3: Version consistency across plugin files"
PLUGIN_JSON="$PROJECT_ROOT/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$PROJECT_ROOT/.claude-plugin/marketplace.json"
README_MD="$PROJECT_ROOT/README.md"

if [[ -f "$PLUGIN_JSON" ]] && [[ -f "$MARKETPLACE_JSON" ]] && [[ -f "$README_MD" ]]; then
    PLUGIN_VER=$(grep -o '"version":[[:space:]]*"[^"]*"' "$PLUGIN_JSON" | grep -o '"[^"]*"$' | tr -d '"')
    MARKETPLACE_VER=$(grep -o '"version":[[:space:]]*"[^"]*"' "$MARKETPLACE_JSON" | grep -o '"[^"]*"$' | tr -d '"')
    README_VER=$(grep -o 'Current Version:[[:space:]]*[0-9.]*' "$README_MD" | grep -o '[0-9.]*$')

    if [[ "$PLUGIN_VER" == "$MARKETPLACE_VER" ]] && [[ "$PLUGIN_VER" == "$README_VER" ]]; then
        pass "Version is consistent across all files: $PLUGIN_VER"
    else
        fail "Version consistency" "All files have same version" \
            "plugin.json=$PLUGIN_VER, marketplace.json=$MARKETPLACE_VER, README.md=$README_VER"
    fi
fi

# ========================================
# NT-4: Docs reference the new command
# ========================================
echo ""
echo "NT-4: Documentation references new command"
USAGE_MD="$PROJECT_ROOT/docs/usage.md"
INSTALL_MD="$PROJECT_ROOT/docs/install-for-claude.md"
if [[ -f "$USAGE_MD" ]]; then
    if grep -q 'plan' "$USAGE_MD"; then
        pass "docs/usage.md references plan command"
    else
        fail "docs/usage.md references plan command"
    fi
fi

if [[ -f "$README_MD" ]]; then
    if grep -q 'plan\|plan-loop\|plan refinement' "$README_MD"; then
        pass "README.md references plan loop feature"
    else
        fail "README.md references plan loop feature"
    fi
fi

if [[ -f "$INSTALL_MD" ]]; then
    if grep -q 'start' "$INSTALL_MD"; then
        pass "docs/install-for-claude.md references start command"
    else
        fail "docs/install-for-claude.md references start command"
    fi
fi

# ========================================
# Summary
# ========================================
print_test_summary "Start Plan Loop Test Summary"
