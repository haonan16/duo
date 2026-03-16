# Duo UX Improvement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Duo easier to install and use by adding `/duo:setup`, `/duo:start`, `/duo:help` commands, renaming user-facing "rlcr" to "loop", and improving hook error messages.

**Architecture:** Three pillars implemented as independent tasks: (1) new commands as `.md` files in `commands/` with supporting shell scripts, (2) user-facing terminology rename from "rlcr" to "loop" across state dirs, monitor, and docs, (3) hook message improvements with actionable tips. Existing commands remain unchanged.

**Tech Stack:** Bash scripts, Markdown command files (Claude Code plugin format), existing test framework (`tests/`).

---

## Task 1: Add `/duo:help` command

The simplest new command. Prints a reference card of all commands.

**Files:**
- Create: `commands/help.md`
- Test: `tests/test-help-command.sh`

**Step 1: Write the test**

Create `tests/test-help-command.sh`:

```bash
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
for cmd in "/duo:start" "/duo:run" "/duo:draft" "/duo:plan" "/duo:stop" "/duo:pr" "/duo:pr-stop" "/duo:ask" "/duo:setup" "/duo:help"; do
    if grep -q "$cmd" "$HELP_FILE"; then
        pass "lists $cmd"
    else
        fail "missing $cmd"
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
```

**Step 2: Run test to verify it fails**

Run: `bash tests/test-help-command.sh 2>&1`
Expected: FAIL (help.md does not exist)

**Step 3: Create the command file**

Create `commands/help.md`:

```markdown
---
description: "Show all Duo commands and usage"
hide-from-slash-command-tool: "true"
---

# Duo Help

Print the following reference card to the user exactly as shown:

---

**Duo** - iterative development with AI review

| Command | Purpose |
|---------|---------|
| `/duo:start <file>` | Smart start (auto-detects draft vs plan) |
| `/duo:run <plan>` | Start development loop with explicit plan |
| `/duo:draft --input <f> --output <f>` | Generate plan from draft |
| `/duo:plan --input <f> --output <f>` | Generate and refine plan with Codex |
| `/duo:stop` | Cancel active development loop |
| `/duo:pr --claude\|--codex` | Start PR review loop |
| `/duo:pr-stop` | Cancel PR review loop |
| `/duo:ask <question>` | One-shot Codex consultation |
| `/duo:setup` | Install, configure, verify prerequisites |
| `/duo:help` | This reference card |

**Monitor** (run in a separate terminal):

```
duo monitor          # Development loop progress
duo monitor --pr     # PR loop progress
```

**Docs:** See `docs/usage.md` for full command reference and options.
```

**Step 4: Run test to verify it passes**

Run: `bash tests/test-help-command.sh 2>&1`
Expected: All PASS

**Step 5: Commit**

```bash
git add commands/help.md tests/test-help-command.sh
git commit -m "feat: add /duo:help command with reference card"
```

---

## Task 2: Add `/duo:start` smart entry point

A command that auto-detects whether the input is a draft or plan and runs the appropriate pipeline.

**Files:**
- Create: `commands/start.md`
- Create: `scripts/detect-plan-structure.sh`
- Test: `tests/test-start-command.sh`

**Step 1: Write the plan detection script test**

Create `tests/test-start-command.sh`:

```bash
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

# Test 7: Command file exists
if [[ -f "$START_FILE" ]]; then
    pass "start.md exists"
else
    fail "start.md does not exist"
fi

# Test 8: Has frontmatter with description
if grep -q '^description:' "$START_FILE"; then
    pass "has description field"
else
    fail "missing description field"
fi

# Test 9: References detect-plan-structure.sh
if grep -q 'detect-plan-structure' "$START_FILE"; then
    pass "references detection script"
else
    fail "missing reference to detection script"
fi

# Test 10: References setup-rlcr-loop.sh for running plans
if grep -q 'setup-rlcr-loop' "$START_FILE"; then
    pass "references setup-rlcr-loop.sh"
else
    fail "missing reference to setup-rlcr-loop.sh"
fi

# Test 11: References validate-gen-plan-io.sh for drafts
if grep -q 'validate-gen-plan-io' "$START_FILE"; then
    pass "references validate-gen-plan-io.sh"
else
    fail "missing reference to validate-gen-plan-io.sh"
fi

# Test 12: Supports --draft-only flag
if grep -q 'draft-only' "$START_FILE"; then
    pass "supports --draft-only flag"
else
    fail "missing --draft-only flag support"
fi

# Test 13: Supports --review-only flag
if grep -q 'review-only' "$START_FILE"; then
    pass "supports --review-only flag"
else
    fail "missing --review-only flag support"
fi

# Test 14: Does not contain rlcr in user-facing text
if grep -v '^#\|^allowed-tools\|scripts/' "$START_FILE" | grep -qi 'rlcr'; then
    fail "contains rlcr in user-facing text"
else
    pass "no rlcr in user-facing text"
fi

teardown

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
```

**Step 2: Run test to verify it fails**

Run: `bash tests/test-start-command.sh 2>&1`
Expected: FAIL (files don't exist)

**Step 3: Create the plan detection script**

Create `scripts/detect-plan-structure.sh`:

```bash
#!/bin/bash
#
# Detect whether a markdown file has plan structure matching gen-plan-template.md.
#
# A valid plan must have ALL of these sections (matching the template):
#   - "## Goal Description"
#   - "## Acceptance Criteria" with at least one "AC-" entry
#   - "## Path Boundaries"
#
# Exit 0 = plan (matches template structure)
# Exit 1 = draft or invalid (missing required sections)
#
# Usage: detect-plan-structure.sh <file>
#

set -euo pipefail

FILE="${1:-}"

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
    exit 1
fi

# Check for the three required sections from gen-plan-template.md
grep -q '## Goal Description' "$FILE" || exit 1
grep -q '## Acceptance Criteria' "$FILE" || exit 1
grep -q 'AC-[0-9]' "$FILE" || exit 1
grep -q '## Path Boundaries' "$FILE" || exit 1

exit 0
```

Make executable: `chmod +x scripts/detect-plan-structure.sh`

**Step 4: Create the command file**

Create `commands/start.md`:

```markdown
---
description: "Smart start - auto-detects draft vs plan and runs the appropriate pipeline"
argument-hint: "[path/to/file.md] [--draft-only] [--review-only] [OPTIONS]"
allowed-tools:
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/detect-plan-structure.sh:*)"
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-rlcr-loop.sh:*)"
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
---

# Duo Smart Start

This command provides a guided entry point that auto-detects what to do.

## Argument Parsing

Parse `$ARGUMENTS` for:
- `<file>` -- first positional argument (a markdown file path)
- `--draft-only` -- stop after plan generation, do not start the development loop
- `--review-only` -- skip implementation, go directly to code review
- All other flags are passed through to the underlying command

## Decision Logic

### Case 1: `--review-only` flag present

Run the development loop in skip-impl mode. Remove `--review-only` from the arguments and run the setup script directly:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-rlcr-loop.sh" --skip-impl <remaining-args>
```

Report: "Starting code review (skipping implementation)..."

### Case 2: No file argument provided

Check for an existing loop state in the project:
1. Look for `.duo/loop/*/state.md` (active loop state)
2. If found, report: "An active loop is already running. Use `/duo:stop` to cancel it first."
3. If not found, report: "No file provided. Usage: `/duo:start <file.md>` or see `/duo:help` for all commands."

Note: There is no "resume" capability. If a loop was cancelled, the user must start a new one.

### Case 3: File argument provided

1. Read the file to confirm it exists. If not found, report the error and stop.

2. Run the detection script:
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/detect-plan-structure.sh" "<file>"
   ```

3. **If exit code 0 (plan detected)**:
   - Report: "Detected: plan file (has Acceptance Criteria). Starting development loop..."
   - Run the setup script directly:
     ```bash
     "${CLAUDE_PLUGIN_ROOT}/scripts/setup-rlcr-loop.sh" <file> <passthrough-options>
     ```
   - Then follow the same post-setup instructions as `commands/run.md` (Goal Tracker, summary writing, exit rules)

4. **If exit code 1 (draft detected)**:
   - Report: "Detected: draft document (no plan structure). Generating plan first..."
   - Determine output path: `docs/plans/<input-basename>-plan.md`
     - Example: `ideas.md` produces `docs/plans/ideas-plan.md`
   - If `--draft-only` flag is present:
     - Run IO validation: `"${CLAUDE_PLUGIN_ROOT}/scripts/validate-gen-plan-io.sh" --input <file> --output <output-path>`
     - Then follow the same draft workflow as `commands/draft.md` (relevance check, analysis, plan generation)
     - After completion, report the output path and stop
   - If `--draft-only` flag is NOT present:
     - Run the full draft workflow (same as `commands/draft.md`)
     - After draft completes successfully, report: "Plan generated. Starting development loop..."
     - Run the setup script directly:
       ```bash
       "${CLAUDE_PLUGIN_ROOT}/scripts/setup-rlcr-loop.sh" <output-path> <passthrough-options>
       ```
     - Then follow the same post-setup instructions as `commands/run.md`

## Error Handling

- If the file does not exist: "File not found: <path>. Please check the path and try again."
- If the draft workflow fails: Report the error and stop. Do not proceed to the development loop.
- If setup-rlcr-loop.sh fails: Report the error.

## Important: Command Composition

This command does NOT invoke other slash commands (that is not supported by the plugin system).
Instead, it directly calls the same scripts and follows the same inline instructions that
`commands/run.md` and `commands/draft.md` use. The allowed-tools list in the frontmatter
includes all tools needed for both the draft and run workflows.
```

**Step 5: Run test to verify it passes**

Run: `bash tests/test-start-command.sh 2>&1`
Expected: All PASS

**Step 6: Commit**

```bash
git add commands/start.md scripts/detect-plan-structure.sh tests/test-start-command.sh
git commit -m "feat: add /duo:start smart entry point with plan detection"
```

---

## Task 3: Add `/duo:setup` command

Verifies prerequisites, installs skills for non-Claude platforms, configures monitor.

**Files:**
- Create: `commands/setup.md` (Claude Code slash command)
- Create: `scripts/setup-environment.sh` (shared logic, called by both paths)
- Create: `scripts/setup.sh` (standalone entry point for non-Claude platforms)
- Test: `tests/test-setup-command.sh`

**Step 1: Write the setup script test**

Create `tests/test-setup-command.sh`:

```bash
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

# --- commands/setup.md tests ---

# Test 12: Command file exists
if [[ -f "$SETUP_CMD" ]]; then
    pass "setup.md exists"
else
    fail "setup.md does not exist"
fi

# Test 13: Has frontmatter
if head -1 "$SETUP_CMD" | grep -q '^---'; then
    pass "has frontmatter"
else
    fail "missing frontmatter"
fi

# Test 14: References setup-environment.sh
if grep -q 'setup-environment' "$SETUP_CMD"; then
    pass "references setup script"
else
    fail "missing reference to setup script"
fi

# Test 15: Mentions monitor setup
if grep -q 'monitor\|duo.sh' "$SETUP_CMD"; then
    pass "mentions monitor setup"
else
    fail "missing monitor setup instructions"
fi

teardown

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
```

**Step 2: Run test to verify it fails**

Run: `bash tests/test-setup-command.sh 2>&1`
Expected: FAIL (files don't exist)

**Step 3: Create the environment setup script**

Create `scripts/setup-environment.sh`:

```bash
#!/bin/bash
#
# Duo environment setup - verifies prerequisites and configures shell.
#
# Usage:
#   setup-environment.sh --check-prereqs    Check prerequisites only
#   setup-environment.sh --configure-shell  Add monitor source to shell RC
#   setup-environment.sh --detect-platform  Detect available AI platforms
#   setup-environment.sh --install-skills   Install skills for detected platforms
#
# Exit codes:
#   0 = success (all prereqs found, or action completed)
#   1 = some prereqs missing (printed to stdout)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' NC=''
fi

check_tool() {
    local name="$1"
    local install_hint="$2"
    local required="$3"  # "required" or "optional"

    if command -v "$name" >/dev/null 2>&1; then
        local version
        version="$("$name" --version 2>/dev/null | head -1 || echo "installed")"
        printf "${GREEN}OK${NC}   %-10s %s\n" "$name" "$version"
        return 0
    else
        if [[ "$required" == "required" ]]; then
            printf "${RED}MISS${NC} %-10s %s\n" "$name" "$install_hint"
        else
            printf "${YELLOW}MISS${NC} %-10s %s (optional)\n" "$name" "$install_hint"
        fi
        return 1
    fi
}

check_prereqs() {
    echo "Checking prerequisites..."
    echo ""

    local missing=0

    check_tool "git" "https://git-scm.com/downloads" "required" || missing=$((missing + 1))
    check_tool "jq" "https://jqlang.github.io/jq/download/" "required" || missing=$((missing + 1))
    check_tool "codex" "npm install -g @openai/codex" "required" || missing=$((missing + 1))
    check_tool "gh" "https://cli.github.com/ (needed for /duo:pr)" "optional" || true

    echo ""

    if [[ "$missing" -gt 0 ]]; then
        echo "Missing $missing required tool(s). Install them and re-run /duo:setup."
        return 1
    else
        echo "All required prerequisites found."
        return 0
    fi
}

detect_platform() {
    local platforms=""

    if command -v claude >/dev/null 2>&1; then
        platforms="${platforms}claude "
    fi
    if command -v codex >/dev/null 2>&1; then
        platforms="${platforms}codex "
    fi
    if command -v kimi >/dev/null 2>&1; then
        platforms="${platforms}kimi "
    fi

    if [[ -z "$platforms" ]]; then
        echo "none"
    else
        echo "$platforms"
    fi
}

configure_shell() {
    local duo_sh="$REPO_ROOT/scripts/duo.sh"
    local source_line="source \"$duo_sh\""
    local rc_files=()
    local configured=0

    # Detect shell RC files
    if [[ -f "$HOME/.zshrc" ]]; then
        rc_files+=("$HOME/.zshrc")
    fi
    if [[ -f "$HOME/.bashrc" ]]; then
        rc_files+=("$HOME/.bashrc")
    fi

    if [[ ${#rc_files[@]} -eq 0 ]]; then
        echo "NO_RC_FILES"
        return 1
    fi

    for rc in "${rc_files[@]}"; do
        if grep -qF "duo.sh" "$rc" 2>/dev/null; then
            echo "ALREADY_CONFIGURED:$rc"
            configured=$((configured + 1))
        else
            echo "NEEDS_CONFIGURE:$rc"
        fi
    done

    if [[ "$configured" -eq "${#rc_files[@]}" ]]; then
        return 0
    fi
    return 0
}

add_to_shell_rc() {
    local rc_file="$1"
    local duo_sh="$REPO_ROOT/scripts/duo.sh"
    local source_line="source \"$duo_sh\""

    if grep -qF "duo.sh" "$rc_file" 2>/dev/null; then
        echo "Already configured in $rc_file"
        return 0
    fi

    printf '\n# Duo monitor helper\n%s\n' "$source_line" >> "$rc_file"
    echo "Added to $rc_file"
}

install_skills() {
    local target="${1:-}"

    if [[ -z "$target" ]]; then
        echo "Usage: setup-environment.sh --install-skills <kimi|codex|both>"
        return 1
    fi

    "$REPO_ROOT/scripts/install-skill.sh" --target "$target"
}

# --- Main ---

case "${1:-}" in
    --check-prereqs)
        check_prereqs
        ;;
    --detect-platform)
        detect_platform
        ;;
    --configure-shell)
        configure_shell
        ;;
    --add-to-rc)
        [[ -n "${2:-}" ]] || { echo "Usage: --add-to-rc <rc-file>"; exit 1; }
        add_to_shell_rc "$2"
        ;;
    --install-skills)
        install_skills "${2:-}"
        ;;
    -h|--help)
        cat <<'EOF'
Duo environment setup

Usage:
  setup-environment.sh --check-prereqs     Check prerequisites
  setup-environment.sh --detect-platform   Detect AI platforms
  setup-environment.sh --configure-shell   Check shell RC status
  setup-environment.sh --add-to-rc <file>  Add monitor to RC file
  setup-environment.sh --install-skills <target>  Install skills
EOF
        ;;
    *)
        echo "Unknown option: ${1:-}"
        echo "Run with --help for usage"
        exit 1
        ;;
esac
```

Make executable: `chmod +x scripts/setup-environment.sh`

**Step 4: Create the command file**

Create `commands/setup.md`:

```markdown
---
description: "Install, configure, and verify Duo prerequisites"
allowed-tools:
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh:*)"
  - "AskUserQuestion"
hide-from-slash-command-tool: "true"
---

# Duo Setup

Guide the user through setting up Duo. Run each phase in order.

## Phase 1: Check Prerequisites

Run the prerequisite check:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh" --check-prereqs
```

Report the results to the user. If required tools are missing, show install instructions and ask if they want to continue anyway or install first.

## Phase 2: Detect Platform

Run platform detection:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh" --detect-platform
```

Parse the output:
- If running inside Claude Code (this session), report: "You are using Claude Code. The plugin is already active."
- If `codex` or `kimi` are detected, ask if the user wants to install skills for those platforms:

Use AskUserQuestion:
- Question: "Detected additional platforms. Install Duo skills for them?"
- Options based on which platforms were detected (codex, kimi, or both)
- Include a "Skip" option

If the user chooses to install, run:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh" --install-skills <target>
```

## Phase 3: Configure Monitor

Run shell RC check:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh" --configure-shell
```

Parse each line:
- `ALREADY_CONFIGURED:<file>`: Report that monitor is already set up in that file
- `NEEDS_CONFIGURE:<file>`: Ask user if they want to add the monitor helper to that file
- `NO_RC_FILES`: Report that no shell RC files were found

If the user approves adding to a file:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh" --add-to-rc "<file>"
```

Report: "Monitor configured. Run `source <file>` or open a new terminal to use `duo monitor`."

## Phase 4: Print Getting Started

After all phases, print:

```
Setup complete!

Quick start:
  /duo:start <file.md>   Generate plan and start development
  duo monitor             Monitor progress (in another terminal)

All commands: /duo:help
```
```

**Step 5: Create the standalone setup script for non-Claude platforms**

Create `scripts/setup.sh`:

```bash
#!/bin/bash
#
# Standalone Duo setup for non-Claude platforms.
# Runs prerequisite checks, skill installation, and shell configuration
# interactively from the terminal (no Claude Code needed).
#
# Usage: ./scripts/setup.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

echo "=== Duo Setup ==="
echo ""

# Phase 1: Check prerequisites
"$SCRIPT_DIR/setup-environment.sh" --check-prereqs || true
echo ""

# Phase 2: Detect and install for platforms
PLATFORMS="$("$SCRIPT_DIR/setup-environment.sh" --detect-platform)"
echo "Detected platforms: $PLATFORMS"

for platform in $PLATFORMS; do
    case "$platform" in
        codex|kimi)
            read -rp "Install Duo skills for $platform? [y/N] " answer
            if [[ "$answer" =~ ^[Yy] ]]; then
                "$SCRIPT_DIR/setup-environment.sh" --install-skills "$platform"
            fi
            ;;
    esac
done
echo ""

# Phase 3: Configure monitor
echo "Checking shell configuration..."
"$SCRIPT_DIR/setup-environment.sh" --configure-shell | while IFS= read -r line; do
    case "$line" in
        ALREADY_CONFIGURED:*)
            echo "Monitor already configured in ${line#ALREADY_CONFIGURED:}"
            ;;
        NEEDS_CONFIGURE:*)
            rc_file="${line#NEEDS_CONFIGURE:}"
            read -rp "Add Duo monitor helper to $rc_file? [y/N] " answer
            if [[ "$answer" =~ ^[Yy] ]]; then
                "$SCRIPT_DIR/setup-environment.sh" --add-to-rc "$rc_file"
            fi
            ;;
        NO_RC_FILES)
            echo "No shell RC files found (.bashrc/.zshrc)"
            ;;
    esac
done

echo ""
echo "Setup complete!"
echo ""
echo "Quick start (in Claude Code):"
echo "  /duo:start <file.md>   Generate plan and start development"
echo ""
echo "Monitor (in another terminal):"
echo "  duo monitor"
```

Make executable: `chmod +x scripts/setup.sh`

**Step 6: Run test to verify it passes**

Run: `bash tests/test-setup-command.sh 2>&1`
Expected: All PASS

**Step 7: Commit**

```bash
git add commands/setup.md scripts/setup-environment.sh scripts/setup.sh tests/test-setup-command.sh
git commit -m "feat: add /duo:setup command and standalone setup script"
```

---

## Task 4: Rename user-facing "rlcr" to "loop"

Rename the state directory from `.duo/rlcr/` to `.duo/loop/` and update the monitor command from `duo monitor rlcr` to `duo monitor` (with `--pr` flag for PR loops).

**Files:**
- Modify: `scripts/duo.sh` (monitor entry point: add default subcommand and --pr flag)
- Modify: `commands/stop.md` (user-facing "RLCR" text in description and body)
- Modify: `commands/pr-stop.md` (user-facing "RLCR" reference)
- Modify: `commands/run.md` (user-facing "RLCR" in heading)
- Modify: `docs/usage.md` (monitor commands, terminology)
- Modify: `docs/install-for-claude.md` (monitor instructions)
- Modify: `README.md` (monitor instructions, quick start)
- Test: existing test suite must pass after changes

**Scope: user-facing text only.** On-disk paths (`.duo/rlcr/`), script filenames, hooks, and internal variables are NOT changed. This keeps the blast radius small and avoids migration complexity.

**Approach:**

1. Replace user-facing "RLCR" with "development loop" or "loop" in commands/*.md and docs
2. Update the monitor function to accept `duo monitor` as default and `duo monitor --pr`
3. Update docs to use new monitor syntax
4. Run test suite to verify nothing breaks

**Step 1: Replace user-facing "RLCR" in command files**

Update all `commands/*.md` files that contain user-facing "RLCR" text:
- `commands/stop.md`: Change `description: "Cancel active RLCR loop"` to `description: "Cancel active development loop"`, change `# Cancel RLCR Loop` to `# Cancel Development Loop`, change "No active RLCR loop found" to "No active loop found"
- `commands/pr-stop.md`: Change `.duo/rlcr/` to `.duo/loop/` and "RLCR loops" to "development loops"
- `commands/run.md`: Change `# Start RLCR Loop` to `# Start Development Loop` and any user-facing "RLCR" in descriptions (keep internal references like `setup-rlcr-loop.sh` since those are script names)

**Step 2c: Add dual-read migration for in-flight loops**

To avoid breaking in-flight loops after upgrade, keep the on-disk storage path stable at `.duo/rlcr/` and only rename user-facing CLI terms and documentation. This is the safest approach because:
- `setup-rlcr-loop.sh`, `cancel-rlcr-loop.sh`, and all hooks hard-code `.duo/rlcr` in dozens of places
- Dual-read fallback across setup, cancel, hooks, and monitor is fragile and hard to test
- The user never types `.duo/rlcr` -- it is an internal implementation detail

**What changes (user-facing only):**
- `duo monitor rlcr` becomes `duo monitor` (keep `rlcr` as hidden alias)
- `duo monitor pr` becomes `duo monitor --pr` (keep `pr` as hidden alias)
- All docs, command descriptions, and error messages say "loop" not "RLCR"
- The `.duo/rlcr/` on-disk path stays unchanged

**What does NOT change:**
- `.duo/rlcr/` directory path in scripts, hooks, and tests
- Script filenames (`setup-rlcr-loop.sh`, `cancel-rlcr-loop.sh`)
- Internal variable names

**Step 2: Update the monitor entry point in `scripts/duo.sh`**

The `duo()` function currently dispatches on `duo monitor rlcr` and `duo monitor pr`. Change to:
- `duo monitor` (no arg or `--loop`) = development loop monitor (was `duo monitor rlcr`)
- `duo monitor --pr` = PR loop monitor (was `duo monitor pr`)
- Keep `duo monitor rlcr` and `duo monitor pr` as hidden aliases for backward compatibility

**Step 3: Update user-facing docs**

- `docs/usage.md`: Change `duo monitor rlcr` to `duo monitor`, `duo monitor pr` to `duo monitor --pr`
- `docs/install-for-claude.md`: Same changes in monitor section
- `README.md`: Same changes in quick start

**Step 4: Run the full test suite**

Run: `bash tests/run-all-tests.sh 2>&1`
Expected: All tests pass. If any fail, fix them -- the failures will be from hardcoded `.duo/rlcr` paths in test assertions.

**Step 5: Verify no user-facing "RLCR" remains in docs and commands**

Run: `grep -ri 'rlcr' commands/ docs/ README.md | grep -v 'docs/plans/'`
Expected: No matches. All user-facing text should say "loop" or "development loop" instead of "RLCR".

Internal files (hooks/, scripts/, tests/, skills/) will still contain "rlcr" in variable names, script filenames, and `.duo/rlcr` paths -- this is expected and correct.

**Step 6: Commit**

```bash
git add -A
git commit -m "refactor: rename user-facing rlcr to loop in state dirs, monitor, and docs"
```

---

## Task 5: Improve hook error messages

Add actionable tips to all block messages across hooks and templates.

**Files:**
- Modify: `hooks/loop-plan-file-validator.sh` (12 block messages)
- Modify: `hooks/loop-codex-stop-hook.sh` (24 block messages)
- Modify: `hooks/pr-loop-stop-hook.sh` (14 block messages)
- Modify: `hooks/loop-bash-validator.sh` (block messages for bash workaround attempts)
- Modify: `hooks/loop-write-validator.sh` (block messages for write attempts)
- Modify: `hooks/loop-edit-validator.sh` (block messages for edit attempts)
- Modify: `prompt-template/block/state-file-modification.md` (user-facing block text)
- Modify: `prompt-template/block/finalize-state-file-modification.md` (user-facing block text)
- Modify: Other `prompt-template/block/*.md` files that contain user-facing error text without actionable guidance
- Test: existing test suite must pass

**Step 0: Inventory all block message sources**

Before editing, do a comprehensive inventory:
1. Run `grep -r '"decision".*"block"' hooks/` to find all JSON block responses in hook scripts
2. Run `grep -r '"decision".*"block"' hooks/lib/` to find block responses in shared helpers
3. Read all files in `prompt-template/block/` -- these are template messages loaded by hooks and shown to users. Each one should be reviewed for clarity and actionable guidance.

This inventory supersedes the file list above -- if additional sources are found, include them.

**Step 1: Categorize block messages**

Read each file from the inventory and categorize every block message by type:
- State file protection -- tip: "Use /duo:stop to cancel the active loop"
- Git branch mismatch -- tip: "Switch back to the original branch or cancel with /duo:stop"
- Git operation failure -- tip: "Check git status and try again"
- Schema version mismatch -- tip: "Cancel the loop with /duo:stop and start a new one"
- Plan file modification -- tip: "The plan file is read-only during the loop"
- Exit blocked by Codex -- tip: "Codex found issues. Address the feedback above and try again"

**Step 2: Add tips to each block message**

For each block message, append a `\n\nTip: <actionable guidance>` to the `reason` field. Example:

Before:
```json
"reason": "Git branch has changed during RLCR loop.\n\nStarted on: $START_BRANCH\nCurrent: $CURRENT_BRANCH"
```

After:
```json
"reason": "Git branch has changed during the loop.\n\nStarted on: $START_BRANCH\nCurrent: $CURRENT_BRANCH\n\nTip: Switch back to $START_BRANCH or cancel the loop with /duo:stop"
```

Also replace any user-facing "RLCR" text with "development loop" or just "loop" in the reason strings.

**Step 3: Run the full test suite**

Run: `bash tests/run-all-tests.sh 2>&1`
Expected: All tests pass. Some tests may assert on exact error message text -- update those assertions.

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add actionable tips to hook block messages"
```

---

## Task 6: Update docs and usage guide

Update all documentation to reflect the new commands and terminology.

**Files:**
- Modify: `docs/usage.md` (add new commands, update terminology)
- Modify: `docs/install-for-claude.md` (simplify with /duo:setup reference)
- Modify: `README.md` (update quick start with /duo:start)
- Modify: `docs/install-for-codex.md` (reference /duo:setup)
- Modify: `docs/install-for-kimi.md` (reference /duo:setup)

**Step 1: Update `docs/usage.md`**

Add entries for `/duo:start`, `/duo:setup`, `/duo:help` to the Commands table. Update the monitor section to use `duo monitor` instead of `duo monitor rlcr`.

**Step 2: Update `README.md` quick start**

Change:
```markdown
1. Generate a plan:  /duo:draft --input draft.md --output docs/plan.md
2. Run the loop:     /duo:run docs/plan.md
3. Monitor:          duo monitor rlcr
```

To:
```markdown
1. Start development: /duo:start draft.md
2. Monitor progress:  duo monitor  (in another terminal)
```

**Step 3: Update install docs**

In `docs/install-for-claude.md`, add a note after installation:
```
After installing, run `/duo:setup` to verify prerequisites and configure monitoring.
```

In `docs/install-for-codex.md` and `docs/install-for-kimi.md`, mention that `/duo:setup` can also handle skill installation when run from Claude Code.

**Step 4: Verify no broken links or references**

Run: `bash tests/test-template-references.sh 2>&1`
Expected: All PASS

**Step 5: Commit**

```bash
git add -A
git commit -m "docs: update usage guide, README, and install docs for new UX"
```

---

## Task 7: Version bump and final verification

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

**Step 1: Bump version to 1.17.0**

Edit all three files to change `1.16.0` to `1.17.0`.

**Step 2: Register new commands in `tests/run-all-tests.sh`**

Add the new test files to the test runner if they are not auto-discovered.

**Step 3: Run the full test suite**

Run: `bash tests/run-all-tests.sh 2>&1`
Expected: All tests pass.

**Step 4: Final grep verification**

Run: `grep -ri 'rlcr' --include='*.md' . | grep -v 'docs/plans/' | grep -v '.git/' | grep -v 'SKILL.md'`
Expected: No user-facing "rlcr" references in docs.

**Step 5: Commit**

```bash
git add -A
git commit -m "chore: bump version to 1.17.0 for UX improvements"
```

---

## Summary

| Task | Description | Type | Depends On |
|------|-------------|------|------------|
| 1 | `/duo:help` command | New command | - |
| 2 | `/duo:start` smart entry | New command + script | - |
| 3 | `/duo:setup` command | New command + script | - |
| 4 | Rename user-facing rlcr to loop | Content edit (commands, docs, monitor) | - |
| 5 | Improve hook messages | Content edit (50 messages) | Task 4 |
| 6 | Update docs | Content edit | Tasks 1-5 |
| 7 | Version bump + verify | Edit + test | Tasks 1-6 |

Tasks 1, 2, 3, and 4 can run in parallel. Task 5 depends on Task 4 (terminology). Task 6 depends on all feature tasks. Task 7 depends on everything.
