# Merge /duo:plan into /duo:start

## Problem

Currently `/duo:start` already auto-detects whether input is a draft or a plan (per commit ba7ff6f). This makes `/duo:plan` redundant as a separate command since `start` can route to plan generation automatically.

## Goal

Remove `/duo:plan` as a standalone command and fold its functionality entirely into `/duo:start`. This reduces the command surface from 8 to 7 commands, eliminating user confusion about which command to use when they have a draft.

## Scope

1. Remove the `commands/plan.md` command file (or merge its content into `commands/start.md`)
2. Ensure `/duo:start` handles all plan generation cases that `/duo:plan` currently handles, including the `--skip-review` flag
3. Update all references to `/duo:plan` across the codebase:
   - CLAUDE.md command table
   - Help command output
   - Documentation files
   - Tests
   - Any scripts that reference the plan command
4. Keep all plan generation logic intact -- only the entry point changes

## Constraints

- Plan generation behavior must remain identical
- The `--skip-review` flag (or equivalent) must still be accessible through `/duo:start`
- No breaking changes to the plan generation output format
- All existing tests for plan functionality must continue to pass (adapted to new entry point)
