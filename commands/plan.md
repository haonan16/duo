---
description: "Generate implementation plan from draft, optionally refine with Codex review"
argument-hint: "--input <path/to/draft.md> --output <path/to/plan.md> [--skip-review] [--max N] [--codex-model MODEL:EFFORT] [--codex-timeout SECONDS]"
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
---

# Generate Plan

This command generates an implementation plan from a draft document. By default, it then iteratively refines the plan using Codex critique until Codex approves or max rounds are reached. Use `--skip-review` to generate the plan without Codex refinement.

## Argument Parsing

Parse the following arguments from `$ARGUMENTS`:

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `--input` | Yes | - | Path to the input draft file |
| `--output` | Yes | - | Path to the output plan file |
| `--skip-review` | No | false | Skip Codex refinement loop, generate plan only (Round 0) |
| `--max` | No | 5 | Maximum number of refinement rounds (including Round 0) |
| `--codex-model` | No | - | Codex model and effort level (e.g., `o4-mini:high`) |
| `--codex-timeout` | No | - | Timeout in seconds for Codex calls |

Build a `CODEX_OPTS` string from the optional codex flags:
- If `--codex-model` is provided, append `--model <value>` to `CODEX_OPTS`
- If `--codex-timeout` is provided, append `--timeout <value>` to `CODEX_OPTS`
- If neither is provided, `CODEX_OPTS` remains empty

---

## Round 0: Generate Initial Plan

### Phase 1: IO Validation

Execute the validation script with the parsed input and output paths:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/validate-gen-plan-io.sh" --input <INPUT_PATH> --output <OUTPUT_PATH>
```

**Handle exit codes:**
- Exit code 0: The script has already created the output file with template structure and original draft appended. Continue to Phase 2.
- Exit code 1: Report "Input file not found" and stop.
- Exit code 2: Report "Input file is empty" and stop.
- Exit code 3: Report "Output directory does not exist - please create it" and stop.
- Exit code 4: Report "Output file already exists - please choose another path" and stop.
- Exit code 5: Report "No write permission to output directory" and stop.
- Exit code 6: Report "Invalid arguments" and show usage, then stop.
- Exit code 7: Report "Plan template file not found - plugin configuration error" and stop.

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

Deeply think and generate the plan following the structure defined in `prompt-template/plan/gen-plan-template.md`.

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

The output file already contains the plan template structure and the original draft content (combined during IO validation). Now complete the plan:

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

## Round 1+: Iterative Refinement

For each round (starting at round 1), perform the following steps. Continue until Codex approves or the maximum number of rounds is reached.

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

## Loop Exit

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

## Error Handling

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
