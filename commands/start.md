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
1. Look for `.duo/loop/*/state.md` (active loop state files)
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
