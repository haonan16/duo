# Rename Humanize to Duo - Design Document

## Overview

Rename the entire plugin from "humanize" to "duo" with shorter, memorable command names. Clean break with no backward compatibility. All-at-once rename across the entire codebase.

## Plugin Identity

| Field | Before | After |
|-------|--------|-------|
| Plugin name | humanize | duo |
| Marketplace owner | humania (humania-org) | duo-dev |
| Repo URL | github.com/humania-org/humanize | github.com/duo-dev/duo |
| Install marketplace | /plugin marketplace add humania-org/humanize | /plugin marketplace add duo-dev/duo |
| Install plugin | /plugin install humanize@humania | /plugin install duo@duo-dev |
| Version | 1.15.0 | 1.16.0 |

## Command Rename

| Old file | New file | Old invocation | New invocation |
|----------|----------|----------------|----------------|
| commands/start-rlcr-loop.md | commands/run.md | /humanize:start-rlcr-loop | /duo:run |
| commands/cancel-rlcr-loop.md | commands/stop.md | /humanize:cancel-rlcr-loop | /duo:stop |
| commands/start-plan-loop.md | commands/plan.md | /humanize:start-plan-loop | /duo:plan |
| commands/gen-plan.md | commands/draft.md | /humanize:gen-plan | /duo:draft |
| commands/start-pr-loop.md | commands/pr.md | /humanize:start-pr-loop | /duo:pr |
| commands/cancel-pr-loop.md | commands/pr-stop.md | /humanize:cancel-pr-loop | /duo:pr-stop |

Old command files are deleted. New files created with updated content.

## Internal Renames

### State Directories
- .humanize/ -> .duo/
- .gitignore entry: .humanize* -> .duo*

### Skill Directories and Names
- skills/humanize/ -> skills/duo/ (name: duo)
- skills/humanize-rlcr/ -> skills/duo-rlcr/ (name: duo-rlcr)
- skills/humanize-gen-plan/ -> skills/duo-gen-plan/ (name: duo-gen-plan)
- skills/ask-codex/ stays unchanged

### Environment Variables
- HUMANIZE_SCRIPT_DIR -> DUO_SCRIPT_DIR
- HUMANIZE_HOOKS_LIB_DIR -> DUO_HOOKS_LIB_DIR
- HUMANIZE_ROOT -> DUO_ROOT
- HUMANIZE_CODEX_BYPASS_SANDBOX -> DUO_CODEX_BYPASS_SANDBOX
- {{HUMANIZE_RUNTIME_ROOT}} -> {{DUO_RUNTIME_ROOT}}

### Script File Rename
- scripts/humanize.sh -> scripts/duo.sh
- Monitor command: humanize monitor rlcr -> duo monitor rlcr

### Block Template Renames
- prompt-template/block/git-add-humanize.md -> prompt-template/block/git-add-duo.md
- prompt-template/block/git-not-clean-humanize-local.md -> prompt-template/block/git-not-clean-duo-local.md

### CLAUDE.md
- Update project description and command references

## Testing Strategy

- Update all existing test files to reference new names
- Run full test suite after rename to validate consistency
- No new tests needed -- existing tests cover structure, naming, version consistency

## Scope

- 79 files with 1,121 occurrences of "humanize" to update
- Clean break, no backward compatibility aliases
- GitHub repo rename (duo-dev/duo) done separately on GitHub

## Design Decisions

- Clean break over backward compatibility (single user, no need for deprecation)
- All-at-once over phased (avoids confusing intermediate state)
- Repo name stays in code as duo-dev/duo (actual GitHub rename done separately)
