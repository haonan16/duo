# Plan Refinement Loop Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `/start-plan-loop` command that generates a plan from a draft and iteratively refines it with Codex critique until approved or max rounds reached.

**Architecture:** Lightweight approach -- one new command file (`commands/start-plan-loop.md`), one new Codex prompt template (`prompt-template/codex/plan-review.md`), one automated test file (`tests/test-start-plan-loop.sh`), and doc updates. Reuses existing `validate-gen-plan-io.sh`, `ask-codex.sh`, and `draft-relevance-checker` agent. No hooks, no new scripts.

**Tech Stack:** Markdown command definition, shell scripts (reused), Codex CLI via `ask-codex.sh`

---

## Task 1: Write automated tests for the plan review template

**Files:**
- Create: `tests/test-start-plan-loop.sh`

This test file follows the same pattern as `tests/test-gen-plan.sh` (structure validation with pass/fail helpers) and `tests/test-ask-codex.sh` (mock codex binary).

**Step 1: Write the failing test scaffold**

Create `tests/test-start-plan-loop.sh` with the initial test cases for the template file. These tests will FAIL because the template does not exist yet.

```bash
#!/bin/bash
#
# Tests for start-plan-loop command and plan-review template
#
# Validates:
#   - plan-review.md template exists and has required structure
#   - start-plan-loop.md command exists with valid frontmatter
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
echo "PT-6: Command file structure validation"
PLAN_LOOP_CMD="$COMMANDS_DIR/start-plan-loop.md"
if [[ -f "$PLAN_LOOP_CMD" ]]; then
    pass "start-plan-loop.md command file exists"
else
    fail "start-plan-loop.md command file exists" "File exists" "File not found"
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
for CHECK_FILE in "$PLAN_REVIEW_TEMPLATE" "$PLAN_LOOP_CMD"; do
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
if [[ "start-plan-loop" =~ ^[a-z][a-z0-9-]*$ ]]; then
    pass "start-plan-loop follows valid naming convention"
else
    fail "start-plan-loop has invalid name format"
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
    if grep -q 'start-plan-loop' "$USAGE_MD"; then
        pass "docs/usage.md references start-plan-loop"
    else
        fail "docs/usage.md references start-plan-loop"
    fi
fi

if [[ -f "$README_MD" ]]; then
    if grep -q 'start-plan-loop\|plan-loop\|plan refinement' "$README_MD"; then
        pass "README.md references plan loop feature"
    else
        fail "README.md references plan loop feature"
    fi
fi

if [[ -f "$INSTALL_MD" ]]; then
    if grep -q 'start-plan-loop' "$INSTALL_MD"; then
        pass "docs/install-for-claude.md references start-plan-loop"
    else
        fail "docs/install-for-claude.md references start-plan-loop"
    fi
fi

# ========================================
# Summary
# ========================================
print_test_summary "Start Plan Loop Test Summary"
```

**Step 2: Make the test executable and run it to verify failures**

Run: `chmod +x tests/test-start-plan-loop.sh && bash tests/test-start-plan-loop.sh 2>&1 || true`
Expected: FAIL on PT-1 through PT-5 (template does not exist), FAIL on PT-6 through PT-10 (command does not exist), PASS on PT-11 (integration contract), FAIL on NT-4 (docs not updated). This confirms the tests catch missing files.

**Step 3: Commit the test file**

```bash
git add tests/test-start-plan-loop.sh
git commit -m "test: add failing tests for start-plan-loop command and plan-review template"
```

---

## Task 2: Create the Codex plan review prompt template

**Files:**
- Create: `prompt-template/codex/plan-review.md`

**Step 1: Write the template file**

Create `prompt-template/codex/plan-review.md`:

```markdown
# Plan Review - Round {{CURRENT_ROUND}}

## Original Draft

The original draft that this plan was generated from is preserved at the bottom of the plan file (between "--- Original Design Draft Start ---" and "--- Original Design Draft End ---"). You MUST compare the plan against this original draft to check for drift.

## Current Plan

Below is the current plan content:
<!-- PLAN CONTENT START -->
{{PLAN_CONTENT}}
<!-- PLAN CONTENT END -->

## Review Instructions

Evaluate this implementation plan on the following 6 dimensions:

### 1. Clarity
- Are the Goal Description and Acceptance Criteria unambiguous?
- Is the scope clearly defined?
- Are terms and concepts used consistently?

### 2. Consistency
- Do different sections contradict each other?
- Do Path Boundaries align with Acceptance Criteria?
- Do Milestones cover all Acceptance Criteria?

### 3. Completeness
- Are there missing edge cases in Acceptance Criteria?
- Are there missing dependencies or prerequisites?
- Do negative tests cover important failure modes?
- Are there gaps in the Milestones sequence?

### 4. Functionality
- Would the proposed approach actually work for this codebase?
- Are there technical limitations not addressed?
- Could the approach negatively impact existing functionality?

### 5. Feasibility
- Are Acceptance Criteria testable and verifiable?
- Are Path Boundaries realistic for this codebase?
- Are the suggested approaches in Feasibility Hints sound?

### 6. Draft Alignment
- Does the plan faithfully represent the original draft intent?
- Has any requirement from the draft been lost, weakened, or changed?
- Has scope crept beyond what the draft specified?

## Output Format

For each issue found, output:

[CATEGORY] Description of the issue
  Suggestion: How to fix it

Where CATEGORY is one of: CLARITY, CONSISTENCY, COMPLETENESS, FUNCTIONALITY, FEASIBILITY, ALIGNMENT.

If NO issues are found across all 6 dimensions, output only:

APPROVED

**CRITICAL**: Only output "APPROVED" if the plan is genuinely ready for implementation with no issues. Be thorough and skeptical. A plan that goes to implementation with flaws wastes far more effort than an extra refinement round.
```

**Step 2: Run tests to verify template tests now pass**

Run: `bash tests/test-start-plan-loop.sh 2>&1 || true`
Expected: PT-1 through PT-5 now PASS. PT-6 through PT-10 still FAIL (command not yet created). PT-13 now PASS.

**Step 3: Commit**

```bash
git add prompt-template/codex/plan-review.md
git commit -m "feat: add Codex plan review prompt template for plan refinement loop"
```

---

## Task 3: Create the start-plan-loop command

**Files:**
- Create: `commands/start-plan-loop.md`

**Step 1: Write the command file**

Create `commands/start-plan-loop.md`. Write the file using the Write tool with the exact content specified below (structured as frontmatter + body to avoid nested fence issues).

The file has two parts: YAML frontmatter and markdown body.

**YAML frontmatter** (between `---` delimiters):

    description: "Start plan refinement loop with Codex review"
    argument-hint: "--input <path/to/draft.md> --output <path/to/plan.md> [--max N] [--codex-model MODEL:EFFORT] [--codex-timeout SECONDS]"
    allowed-tools:
      - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/validate-gen-plan-io.sh:*)"
      - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/ask-codex.sh:*)"
      - "Read"
      - "Glob"
      - "Grep"
      - "Task"
      - "Write"
      - "Edit"
      - "AskUserQuestion"
    hide-from-slash-command-tool: "true"

**Markdown body** (the heading and all content after the closing `---`):

Use `commands/gen-plan.md` as the structural reference. The body must contain these sections in order:

**Section: `# Start Plan Refinement Loop`**

One-line description: "This command generates an implementation plan from a draft document and iteratively refines it using Codex critique. Claude writes/refines the plan, Codex reviews it, and the loop continues until Codex approves or max rounds are reached."

**Section: `## Argument Parsing`**

Table with 5 rows: `--input` (required), `--output` (required), `--max` (default 5), `--codex-model` (optional), `--codex-timeout` (optional). Instruct to build a `CODEX_OPTS` string from the optional codex flags.

**Section: `## Round 0: Generate Initial Plan`**

Six subsections matching gen-plan Phases 1-6:

- Phase 1 IO Validation: call `"${CLAUDE_PLUGIN_ROOT}/scripts/validate-gen-plan-io.sh" --input <INPUT_PATH> --output <OUTPUT_PATH>` in a bash code block. List exit codes 0-7 with messages. Note that exit 0 means the script has already created the output file with template + draft appended.
- Phase 2 Relevance Check: invoke `humanize:draft-relevance-checker` agent (haiku). Handle RELEVANT/NOT_RELEVANT.
- Phase 3 Draft Analysis: 4 dimensions (clarity, consistency, completeness, functionality). Use Explore agents.
- Phase 4 Issue Resolution: AskUserQuestion for issues. Confirm quantitative metrics. Preserve draft content.
- Phase 5 Plan Generation: follow `prompt-template/plan/gen-plan-template.md` structure. All gen-plan generation rules apply.
- Phase 6 Write Plan: Edit tool to update output file. Keep original draft at bottom. Report "Round 0 complete".

**Section: `## Round 1+: Iterative Refinement`**

Five steps per round:

- Step 1 Read Current Plan: Read the output plan file.
- Step 2 Build Codex Review Prompt: Read `${CLAUDE_PLUGIN_ROOT}/prompt-template/codex/plan-review.md`, substitute `{{CURRENT_ROUND}}` and `{{PLAN_CONTENT}}`.
- Step 3 Send to Codex: call `"${CLAUDE_PLUGIN_ROOT}/scripts/ask-codex.sh" $CODEX_OPTS "<constructed review prompt>"` in a bash code block. Note the prompt is passed as positional arg (ask-codex.sh pipes it via stdin to codex exec).
- Step 4 Process Codex Response: if last line is "APPROVED" stop and report success. If issues found, refine with Edit tool preserving draft markers. Proceed to next round.
- Step 5 Report Round Status: round number, issues count, changes summary.

**Section: `## Loop Exit`**

Two cases: APPROVED (report success + path) and max rounds (report + last feedback summary).

**Section: `## Error Handling`**

Three cases: ask-codex.sh failure (report + stop), plan file unreadable (stop), empty Codex response (stop).

**Step 2: Run tests to verify command tests now pass**

Run: `bash tests/test-start-plan-loop.sh 2>&1 || true`
Expected: PT-6 through PT-10 now PASS. NT-4 (docs) still FAIL.

**Step 3: Commit**

```bash
git add commands/start-plan-loop.md
git commit -m "feat: add start-plan-loop command for iterative plan refinement with Codex"
```

---

## Task 4: Update documentation

**Files:**
- Modify: `docs/usage.md` -- add command to table and reference section
- Modify: `README.md` -- add plan loop to Quick Start
- Modify: `docs/install-for-claude.md` -- add to verified commands list

**Step 1: Add to docs/usage.md command table**

In `docs/usage.md`, find the Commands table and add a new row after the `gen-plan` row. The new row text is:

    | `/start-plan-loop --input <draft.md> --output <plan.md>` | Generate and iteratively refine plan with Codex |

**Step 2: Add command reference section to docs/usage.md**

After the `gen-plan` reference section in `docs/usage.md`, add a new `### start-plan-loop` section documenting the command usage block with OPTIONS (`--input`, `--output`, `--max`, `--codex-model`, `--codex-timeout`) and a one-line description: "Generates an implementation plan from a draft document (Round 0), then iteratively refines it with Codex review (Round 1+). The loop stops when Codex outputs APPROVED or max rounds are reached."

**Step 3: Update README.md Quick Start**

In `README.md`, after the existing gen-plan step in Quick Start, add a line:

    Or use the **plan refinement loop** for iterative improvement:

followed by a bash code block containing:

    /humanize:start-plan-loop --input draft.md --output docs/plan.md

**Step 4: Update docs/install-for-claude.md verified commands list**

In `docs/install-for-claude.md`, find the "Verify Installation" section that lists available commands (around line 52). Add `/humanize:start-plan-loop` to the command list, after `/humanize:gen-plan`.

**Step 5: Run tests to verify docs tests pass**

Run: `bash tests/test-start-plan-loop.sh 2>&1 || true`
Expected: All three NT-4 checks PASS (usage.md, README.md, install-for-claude.md).

**Step 6: Commit**

```bash
git add docs/usage.md README.md docs/install-for-claude.md
git commit -m "docs: add start-plan-loop to usage guide, README, and install guide"
```

---

## Task 5: Version bump

Per project rules, every commit on main must include a version bump. Bump from `1.14.0` to `1.15.0` (new feature).

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

**Step 1: Update all three files**

Change `"version": "1.14.0"` to `"version": "1.15.0"` in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Change `Current Version: 1.14.0` to `Current Version: 1.15.0` in `README.md`.

**Step 2: Run the full test suite to verify version consistency**

Run: `bash tests/test-start-plan-loop.sh 2>&1`
Expected: NT-3 (version consistency) PASS. All tests PASS with exit code 0.

**Step 3: Also run existing tests to verify no regressions**

Run: `bash tests/test-gen-plan.sh 2>&1`
Expected: All existing tests still PASS.

**Step 4: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json README.md
git commit -m "chore: bump version to 1.15.0 for plan refinement loop feature"
```

---

## Summary

| Task | Description | New/Modified Files | Depends On |
|------|-------------|-------------------|------------|
| 1 | Write automated tests (RED) | `tests/test-start-plan-loop.sh` | - |
| 2 | Create plan review template | `prompt-template/codex/plan-review.md` | Task 1 |
| 3 | Create command file | `commands/start-plan-loop.md` | Task 2 |
| 4 | Update documentation | `docs/usage.md`, `README.md`, `docs/install-for-claude.md` | Task 3 |
| 5 | Version bump + final verification | 3 version files | Task 4 |

All tasks are sequential. Each task ends with running `tests/test-start-plan-loop.sh` to verify incremental progress (more tests turning GREEN).
