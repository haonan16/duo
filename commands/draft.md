---
description: "Generate implementation plan from draft document (deprecated: use /duo:plan --skip-review)"
argument-hint: "--input <path/to/draft.md> --output <path/to/plan.md>"
allowed-tools:
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/validate-gen-plan-io.sh:*)"
  - "Read"
  - "Glob"
  - "Grep"
  - "Task"
  - "Write"
  - "Edit"
  - "AskUserQuestion"
hide-from-slash-command-tool: "true"
---

# Deprecated: Use /duo:plan --skip-review

This command has been merged into `/duo:plan`. The `--skip-review` flag provides the same behavior (plan generation without Codex refinement).

## What To Do

Report to the user:

> **Note:** `/duo:draft` has been merged into `/duo:plan`. Use `/duo:plan --skip-review` for the same behavior, or `/duo:plan` to also get Codex refinement.
>
> Running your request through `/duo:plan --skip-review` now...

Then execute the same workflow as `commands/plan.md` with `--skip-review` implicitly set. Parse `$ARGUMENTS` for `--input` and `--output`, then follow the `commands/plan.md` workflow (Phase 1 through Phase 6) without proceeding to Round 1+ (Codex refinement).
