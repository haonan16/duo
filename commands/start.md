---
description: "Smart start - auto-detects draft vs plan and runs the appropriate pipeline"
argument-hint: "[path/to/file.md | inline text description] [--plan-only | --draft-only] [--review-only] [OPTIONS]"
allowed-tools:
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/detect-plan-structure.sh:*)"
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-rlcr-loop.sh:*)"
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/validate-gen-plan-io.sh:*)"
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/ask-codex.sh:*)"
  - "Bash(mkdir:*)"
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
  - `<file-or-text>` -- first positional argument(s). Could be a file path OR inline text description
- `--plan-only` or `--draft-only` (alias, kept for backward compatibility) -- stop after plan generation, do not start the development loop
- `--review-only` -- skip implementation, go directly to code review
- All other flags are passed through to the underlying command

## Distinguishing File Paths From Inline Text

When the first positional argument does NOT exist as a file, use this heuristic to decide
whether it was intended as a file path (typo) or inline text:

**Treat as a file path error** if ANY of these are true:
- The argument contains a `/` (looks like a path)
- The argument ends with a common file extension (`.md`, `.txt`, `.markdown`, `.rst`)
- The argument contains a `.` followed by 1-4 alphanumeric characters at the end (looks like `file.ext`)

In this case, report: "File not found: <path>. Please check the path and try again." and stop.

**Treat as inline text** only if the argument does NOT match any of the above patterns.

## Decision Logic

### Case 1: `--review-only` flag present

Run the development loop in skip-impl mode. Remove `--review-only` from the arguments and run the setup script directly:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-rlcr-loop.sh" --skip-impl <remaining-args>
```

Report: "Starting code review (skipping implementation)..."

### Case 2: No file argument provided

Check for an existing loop state in the project:
1. Look for `.duo/rlcr/*/state.md` (active loop state)
2. If found, report: "An active loop is already running. Use `/duo:stop` to cancel it first."
3. If not found, report: "No input provided. Usage: `/duo:start <file.md>` or `/duo:start <description text>`. See `/duo:help` for all commands."

Note: There is no "resume" capability. If a loop was cancelled, the user must start a new one.

### Case 3: Argument provided but file does not exist

Apply the heuristic from "Distinguishing File Paths From Inline Text" above.

**If classified as a file path error**: Report "File not found: <path>. Please check the path and try again." and stop.

**If classified as inline text**: Treat the entire positional argument string as an inline text description of what to build.

1. Collect all positional arguments (everything that is not a recognized flag or flag value) into
   a single string. This is the user's inline description.

2. Generate a draft file from the inline text:
   - Create a timestamped filename: `docs/plans/inline-<YYYYMMDD-HHMMSS>-draft.md`
   - Ensure the `docs/plans/` directory exists (create it if not)
   - Write the inline text to the draft file as-is (do not reformat or embellish)

3. Determine the output plan path: `docs/plans/inline-<YYYYMMDD-HHMMSS>-plan.md`
   (same timestamp as the draft file)

4. If `--plan-only` (or `--draft-only`) flag is present:
   - Run IO validation: `"${CLAUDE_PLUGIN_ROOT}/scripts/validate-gen-plan-io.sh" --input <draft-path> --output <plan-path>`
   - Then follow the same plan generation workflow as `commands/plan.md` with `--skip-review` (relevance check, analysis, plan generation, no Codex refinement)
   - After completion, report the output path and stop

5. If `--plan-only` (or `--draft-only`) flag is NOT present:
   - Run IO validation: `"${CLAUDE_PLUGIN_ROOT}/scripts/validate-gen-plan-io.sh" --input <draft-path> --output <plan-path>`
   - Run the plan generation workflow (same as `commands/plan.md` with `--skip-review`)
   - After plan generation completes successfully, report: "Plan generated from inline text. Starting development loop..."
   - Run the setup script directly:
     ```bash
     "${CLAUDE_PLUGIN_ROOT}/scripts/setup-rlcr-loop.sh" <plan-path> <passthrough-options>
     ```
   - Then follow the same post-setup instructions as `commands/run.md` (Goal Tracker, summary writing, exit rules)

### Case 4: File argument provided and file exists

1. Read the file to confirm it exists.

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
   - If `--plan-only` (or `--draft-only`) flag is present:
     - Run IO validation: `"${CLAUDE_PLUGIN_ROOT}/scripts/validate-gen-plan-io.sh" --input <file> --output <output-path>`
     - Then follow the same plan generation workflow as `commands/plan.md` with `--skip-review`
     - After completion, report the output path and stop
   - If `--plan-only` (or `--draft-only`) flag is NOT present:
     - Run IO validation and plan generation workflow (same as `commands/plan.md` with `--skip-review`)
     - After plan generation completes successfully, report: "Plan generated. Starting development loop..."
     - Run the setup script directly:
       ```bash
       "${CLAUDE_PLUGIN_ROOT}/scripts/setup-rlcr-loop.sh" <output-path> <passthrough-options>
       ```
     - Then follow the same post-setup instructions as `commands/run.md`

## Error Handling

- If the argument looks like a file path but file does not exist (Case 3): "File not found: <path>. Please check the path and try again."
- If the inline draft file cannot be written (Case 3): Report the error and stop.
- If the plan generation workflow fails: Report the error and stop. Do not proceed to the development loop.
- If setup-rlcr-loop.sh fails: Report the error.

## Important: Command Composition

This command does NOT invoke other slash commands (that is not supported by the plugin system).
Instead, it directly calls the same scripts and follows the same inline instructions that
`commands/run.md` and `commands/plan.md` use. The allowed-tools list in the frontmatter
includes all tools needed for both the plan and run workflows.
