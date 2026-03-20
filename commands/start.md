---
description: "Smart start - auto-detects draft vs plan and runs the appropriate pipeline"
argument-hint: "[path/to/file.md | inline text description] [--plan-only | --draft-only] [--review-only] [--skip-review] [--max N] [--codex-model MODEL:EFFORT] [--codex-timeout SECONDS]"
allowed-tools:
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/detect-plan-structure.sh:*)"
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-rlcr-loop.sh:*)"
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/ask-codex.sh:*)"
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh:*)"
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

This command provides a guided entry point that auto-detects what to do. It also serves as the plan generation command (formerly `/duo:plan`).

## Argument Parsing

Parse `$ARGUMENTS` for:
  - `<file-or-text>` -- first positional argument(s). Could be a file path OR inline text description
- `--plan-only` or `--draft-only` (alias, kept for backward compatibility) -- stop after plan generation, do not start the development loop
- `--review-only` -- skip implementation, go directly to code review
- `--skip-review` -- skip Codex refinement loop during plan generation (generate plan only, no iterative review)
- `--max <N>` -- maximum number of Codex refinement rounds including initial generation (default: 5)
- `--codex-model <MODEL:EFFORT>` -- Codex model and reasoning effort level (e.g., `o4-mini:high`)
- `--codex-timeout <SECONDS>` -- timeout in seconds for each Codex review call
- All other flags are passed through to the underlying command

Build a `CODEX_OPTS` string from the optional codex flags:
- If `--codex-model` is provided, append `--model <value>` to `CODEX_OPTS`
- If `--codex-timeout` is provided, append `--timeout <value>` to `CODEX_OPTS`
- If neither is provided, `CODEX_OPTS` remains empty

**Implicit plan-only behavior**: If any of `--max`, `--codex-model`, or `--codex-timeout` are passed WITHOUT `--plan-only`, they imply `--plan-only`. The rationale is that these flags only affect plan generation refinement, so passing them signals intent to focus on plan generation rather than starting a development loop.

## Auto-Setup

Before proceeding with any other logic, check if the Duo CLI is installed:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh" --install-cli
```

This silently installs the wrapper (`~/.duo/duo.sh`) and standalone CLI (`~/.duo/bin/duo`) if they don't already exist. It does NOT modify shell RC files -- that only happens during `/duo:setup`. This ensures `duo monitor` works if the user manually adds `~/.duo/bin` to their PATH, even without running `/duo:setup` first.

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

Run the probe to check for an existing loop:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-rlcr-loop.sh" --probe
```

- If the first line is `RESUME_PROMPT`: An interrupted loop was detected. Read `loop_dir:` and `current_round:` from the output. Report: "Found an interrupted loop at round <current_round>. Run `/duo:run` to resume it, or `/duo:stop` to cancel it." Stop.
- If the first line is `CLEAR` (or probe fails): Report: "No input provided. Usage: `/duo:start <file.md>` or `/duo:start <description text>`. See `/duo:help` for all commands." Stop.

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

4. If `--plan-only` (or `--draft-only`) flag is present (or implied by refinement flags):
   - Run the plan generation workflow: Round 0 (relevance check, analysis, plan generation) as defined in the "Plan Generation Workflow" section below
   - If `--skip-review` is set: Stop after Round 0. Report the output path and stop.
   - If `--skip-review` is NOT set: Continue to the Codex refinement loop (Round 1+) as defined in the "Codex Refinement Loop" section below.
   - After completion, report the output path and stop

5. If `--plan-only` (or `--draft-only`) flag is NOT present (and no refinement flags imply it):
   - Run the plan generation workflow: Round 0 only with `--skip-review` (no Codex refinement)
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
   - If `--plan-only` (or `--draft-only`) flag is present (or implied by refinement flags):
     - Run the plan generation workflow: Round 0 as defined in the "Plan Generation Workflow" section below
     - If `--skip-review` is set: Stop after Round 0. Report the output path and stop.
     - If `--skip-review` is NOT set: Continue to the Codex refinement loop (Round 1+).
     - After completion, report the output path and stop
   - If `--plan-only` (or `--draft-only`) flag is NOT present (and no refinement flags imply it):
     - Run the plan generation workflow: Round 0 only with `--skip-review`
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
Instead, it directly calls the same scripts and follows inline instructions for both the plan
generation and run workflows. The allowed-tools list in the frontmatter includes all tools
needed for both workflows.

---

## Plan Generation Workflow (Round 0)

This section defines the complete plan generation pipeline. It is referenced by Cases 3 and 4 above.

### Phase 1: Seed Output File

1. If the output file already exists, report "Output file already exists: <path>" and stop.
2. Read the plan template: `${CLAUDE_PLUGIN_ROOT}/prompt-template/plan/gen-plan-template.md`
3. Read the input draft file.
4. Write the output file with the following structure:
   - The full template content
   - A blank line
   - `--- Original Design Draft Start ---`
   - A blank line
   - The full draft content
   - A blank line
   - `--- Original Design Draft End ---`

---

### Phase 2: Relevance Check

After IO validation passes, check if the draft is relevant to this repository.

> **Note**: Do not spend too much time on this check. As long as the draft is not completely unrelated to the current project - not like the difference between ship design and cake recipes - it passes.

1. Read the input draft file to get its content.
2. Use the Task tool to invoke the `duo:draft-relevance-checker` agent (haiku model):
   ```
   Task tool parameters:
   - model: "haiku"
   - prompt: Include the draft content and ask the agent to:
     1. Explore the repository structure (README, CLAUDE.md, main files)
     2. Analyze if the draft content relates to this repository
     3. Return either `RELEVANT: <reason>` or `NOT_RELEVANT: <reason>`
   ```

3. **If NOT_RELEVANT**:
   - Report: "The draft content does not appear to be related to this repository."
   - Show the reason from the relevance check.
   - Stop the command.

4. **If RELEVANT**: Continue to Phase 3.

---

### Phase 3: Draft Analysis

Deeply analyze the draft for potential issues. Use Explore agents to investigate the codebase.

#### Analysis Dimensions

1. **Clarity**: Is the draft's intent and goals clearly expressed?
   - Are objectives well-defined?
   - Is the scope clear?
   - Are terms and concepts unambiguous?

2. **Consistency**: Does the draft contradict itself?
   - Are requirements internally consistent?
   - Do different sections align with each other?

3. **Completeness**: Are there missing considerations?
   - Use Explore agents to investigate parts of the codebase the draft might affect
   - Identify dependencies, side effects, or related components not mentioned
   - Check if the draft overlooks important edge cases

4. **Functionality**: Does the design have fundamental flaws?
   - Would the proposed approach actually work?
   - Are there technical limitations not addressed?
   - Could the design negatively impact existing functionality?

#### Exploration Strategy

Use the Task tool with `subagent_type: "Explore"` to investigate:
- Components mentioned in the draft
- Related files and directories
- Existing patterns and conventions
- Dependencies and integrations

---

### Phase 4: Issue Resolution

> **Critical**: The draft document contains the most valuable human input. During issue resolution, NEVER discard or override any original draft content. All clarifications should be treated as incremental additions that supplement the draft, not replacements. Keep track of both the original draft statements and the clarified information.

#### Step 1: Resolve Analysis Issues

If any issues are found during analysis, use AskUserQuestion to clarify with the user.

For each issue category that has problems, present:
- What the issue is
- Why it matters
- Options for resolution (if applicable)

Continue this dialogue until all significant issues are resolved or acknowledged by the user.

#### Step 2: Confirm Quantitative Metrics

After all analysis issues are resolved, check the draft for any quantitative metrics or numeric thresholds, such as:
- Performance targets: "less than 15GB/s", "under 100ms latency"
- Size constraints: "below 300KB", "maximum 1MB"
- Count limits: "more than 10 files", "at least 5 retries"
- Percentage goals: "95% coverage", "reduce by 50%"

For each quantitative metric found, use AskUserQuestion to explicitly confirm with the user:
- Is this a **hard requirement** that must be achieved for the implementation to be considered successful?
- Or is this describing an **optimization trend/direction** where improvement toward the target is acceptable even if the exact number is not reached?

Document the user's answer for each metric, as this distinction significantly affects how acceptance criteria should be written in the plan.

---

### Phase 5: Plan Generation

Deeply think and generate the plan following the structure defined in `${CLAUDE_PLUGIN_ROOT}/prompt-template/plan/gen-plan-template.md`.

#### Generation Rules

1. **Terminology**: Use Milestone, Phase, Step, Section. Never use Day, Week, Month, Year, or time estimates.

2. **No Line Numbers**: Reference code by path only (e.g., `src/utils/helpers.ts`), never by line ranges.

3. **No Time Estimates**: Do not estimate duration, effort, or code line counts.

4. **Conceptual Not Prescriptive**: Path boundaries and suggestions guide without mandating.

5. **AC Format**: All acceptance criteria must use AC-X or AC-X.Y format.

6. **Clear Dependencies**: Show what depends on what, not when things happen.

7. **TDD-Style Tests**: Each acceptance criterion MUST include both positive tests (expected to pass) and negative tests (expected to fail). This follows Test-Driven Development philosophy and enables deterministic verification.

8. **Affirmative Path Boundaries**: Describe upper and lower bounds using affirmative language (what IS acceptable) rather than negative language (what is NOT acceptable).

9. **Respect Deterministic Designs**: If the draft specifies a fixed approach with no choices, reflect this in the plan by narrowing the path boundaries to match the user's specification.

10. **Code Style Constraint**: The generated plan MUST include a section or note instructing that implementation code and comments should NOT contain plan-specific progress terminology such as "AC-", "Milestone", "Step", "Phase", or similar workflow markers. These terms belong in the plan document, not in the resulting codebase.

11. **Draft Completeness Requirement**: The generated plan MUST incorporate ALL information from the input draft document without omission. The draft represents the most valuable human input and must be fully preserved. Any clarifications obtained through Phase 4 should be added incrementally to the draft's original content, never replacing or losing any original requirements. The final plan must be a superset of the draft information plus all clarified details.

---

### Phase 6: Write Plan

The output file already contains the plan template structure and the original draft content (combined in Phase 1). Now complete the plan:

1. Use the **Edit tool** (not Write) to update the plan file with the generated content:
   - Replace template placeholders with actual plan content
   - Keep the original draft section intact at the bottom of the file
   - The final file should contain both the structured plan AND the original draft for reference

2. After updating, read the complete plan file and verify:
   - The plan is complete and comprehensive
   - All sections are consistent with each other
   - The structured plan aligns with the original draft content
   - No contradictions exist between different parts of the document

3. If inconsistencies are found, fix them using the Edit tool.

4. Check if the updated plan file contains multiple languages (e.g., mixed English and Chinese content).
   If multiple languages are detected:
   - Use **AskUserQuestion** to ask the user whether they want to unify the language and which language to use
   - If the user chooses to unify, translate all content to the chosen language using the Edit tool
   - If the user declines, leave the document as-is

5. Report "Round 0 complete" with a summary of the generated plan (path, number of acceptance criteria, whether language was unified).

---

**If `--skip-review` is set**: Stop here. Report the output path and summary. Do not proceed to Round 1+.

---

## Codex Refinement Loop (Round 1+)

For each round (starting at round 1), perform the following steps. Continue until Codex approves or the maximum number of rounds (`--max`, default 5) is reached.

### Step 1: Read Current Plan

Read the output plan file to get its current content.

### Step 2: Build Codex Review Prompt

Read the review prompt template at `${CLAUDE_PLUGIN_ROOT}/prompt-template/codex/plan-review.md`. Substitute the following placeholders:
- `{{CURRENT_ROUND}}` with the current round number
- `{{PLAN_CONTENT}}` with the full content of the current plan file

### Step 3: Send to Codex

Call ask-codex.sh with the constructed review prompt. The prompt is passed as a positional argument (ask-codex.sh pipes it via stdin to codex exec):

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/ask-codex.sh" $CODEX_OPTS "<constructed review prompt>"
```

### Step 4: Process Codex Response

Check the last line of the Codex response:

- **If the last line is "APPROVED"**: The plan has been approved. Stop the loop and proceed to Loop Exit (APPROVED case).
- **If issues are found**: Refine the plan using the Edit tool to address the feedback. Preserve the original draft content markers at the bottom of the file. Do not remove or alter the original draft section. Proceed to the next round.

### Step 5: Report Round Status

Report the following for each completed round:
- Current round number
- Number of issues identified by Codex
- Summary of changes made to address the feedback

---

## Refinement Loop Exit

### APPROVED

If Codex approves the plan:
- Report success to the user
- Show the path to the final approved plan file
- Summarize the total number of rounds completed

### Max Rounds Reached

If the maximum number of rounds is reached without approval:
- Report that the maximum number of refinement rounds has been reached
- Show the path to the current plan file
- Include a summary of the feedback from the last Codex review so the user knows what issues remain

---

## Refinement Error Handling

### ask-codex.sh Failure

If `ask-codex.sh` returns a non-zero exit code or fails to execute:
- Report the error: "Codex review failed. Unable to continue the refinement loop."
- Show the exit code and any error output.
- Stop the loop.

### Plan File Unreadable

If the plan file cannot be read at any point during the refinement loop:
- Report the error: "Cannot read plan file at the specified path."
- Show the file path that was attempted.
- Stop the loop.

### Empty Codex Response

If Codex returns an empty response (no output):
- Report the error: "Codex returned an empty response. Unable to determine plan status."
- Stop the loop.
