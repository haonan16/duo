# Plan Refinement Loop Design

## Overview

Add a `/start-plan-loop` command that generates an implementation plan from a draft document and iteratively refines it using Codex critique. Claude Code writes/refines the plan, Codex reviews it, and the loop continues until Codex approves or max rounds are reached.

## Approach

Lightweight: one new command file + one new Codex prompt template. No hooks, no stop hook, no new scripts.

## New Files

- `commands/start-plan-loop.md` -- command definition
- `prompt-template/codex/plan-review.md` -- Codex critique prompt template

## Reused Components

- `scripts/validate-gen-plan-io.sh` -- IO path validation
- `scripts/ask-codex.sh` -- Codex invocation
- `agents/draft-relevance-checker` -- relevance check (haiku model)
- Gen-plan logic (Phases 3-5 from `commands/gen-plan.md`) -- initial plan generation

## Command Interface

```
/start-plan-loop --input draft.md --output plan.md [--max 5] [--codex-model MODEL:EFFORT] [--codex-timeout SECONDS]
```

### Arguments

- `--input <path>` (required): Path to the draft document
- `--output <path>` (required): Path for the output plan file
- `--max <N>` (optional, default 5): Maximum refinement rounds
- `--codex-model <MODEL:EFFORT>` (optional): Codex model and reasoning effort
- `--codex-timeout <SECONDS>` (optional): Timeout for Codex calls

## Workflow

### Round 0: Generate Initial Plan

1. Validate IO paths using `validate-gen-plan-io.sh`
2. Relevance check using `draft-relevance-checker` agent
3. Draft analysis -- clarity, consistency, completeness, functionality
4. Issue resolution -- ask user clarifying questions via AskUserQuestion
5. Generate initial plan following gen-plan structure
6. Write plan to output file

### Round 1+: Iterative Refinement

1. Call `ask-codex.sh` with the current plan content + `plan-review.md` template
2. Codex evaluates on 6 dimensions (see Codex Review Dimensions below)
3. If Codex outputs "APPROVED" as last line -- stop, report success
4. If Codex has feedback -- Claude reads feedback, refines the plan using Edit tool
5. If max rounds reached -- stop, report current state
6. Otherwise -- go to step 1

### Stop Conditions

- Codex outputs "APPROVED" as the last line of its response
- Maximum rounds reached (default: 5)

## Codex Review Dimensions

The `plan-review.md` template instructs Codex to evaluate:

1. **Clarity**: Are goals and acceptance criteria unambiguous?
2. **Consistency**: Do sections contradict each other?
3. **Completeness**: Are there missing edge cases, dependencies, or acceptance criteria?
4. **Functionality**: Would the proposed approach actually work for this codebase?
5. **Feasibility**: Are acceptance criteria testable? Are path boundaries realistic?
6. **Draft Alignment**: Does the plan still match the original draft intent? Has anything been lost or drifted?

### Output Format

- Issues found: list each issue with category, description, and suggestion
- No issues: output "APPROVED" as the last line

## Plan Structure

Same as gen-plan output:

- Goal Description
- Acceptance Criteria (AC-X format with TDD positive/negative tests)
- Path Boundaries (Upper Bound, Lower Bound, Allowed Choices)
- Feasibility Hints and Suggestions
- Dependencies and Sequence (Milestones)
- Implementation Notes

The original draft content is preserved at the bottom of the plan file so Codex can always compare against original intent.

## Design Decisions

- **No cancel command**: The loop runs within a single session and stops naturally. User can Ctrl+C.
- **No hooks**: Plan refinement is simpler than code review -- no files to guard, no state to enforce.
- **No Goal Tracker**: The draft alignment check in Codex review serves the same purpose for plans.
- **Reuse ask-codex.sh**: Same Codex integration as RLCR, consistent quality.
