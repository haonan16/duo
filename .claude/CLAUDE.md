# Duo

A Claude Code plugin that provides iterative development with independent AI review (Codex). The core workflow is: draft a design, generate a structured plan, refine it with Codex critique, then implement via RLCR (loop with Codex review) cycles.

## Commands

| Command | Purpose |
|---------|---------|
| `/duo:start` | Smart entry point -- auto-detects draft vs plan and runs the appropriate pipeline |
| `/duo:draft` | Generate implementation plan from a draft document |
| `/duo:plan` | Start plan refinement loop with Codex review |
| `/duo:run` | Start iterative development loop with Codex review |
| `/duo:stop` | Cancel active development loop |
| `/duo:pr` | Start PR review loop with bot monitoring |
| `/duo:pr-stop` | Cancel active PR loop |
| `/duo:setup` | Install, configure, and verify Duo prerequisites |
| `/duo:help` | Display all Duo commands and usage reference |

## Project Rules

- Everything about this project, including but not limited to implementations, comments, tests and documentations should be in English. No Emoji or CJK char is allowed.
- If under `main` branch, every commit MUST include a version bump in `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` and `README.md` (the "Current Version" line). If not under `main` branch, please make sure that the current branch's `version` in those three files has a incremental update compared to that of `main` branch. The `version` must be identical in those three files.
- Version number must be in format of `X.Y.Z` where X/Y/Z is numeric number. Version MUST NOT include anything other than `X.Y.Z`. For example, a good version is `9.732.42`; Bad version examples (MUST NOT USE): `3.22.7-alpha` (extra "-alpha" string), `9.77.2 (2026-01-07)` (useless date/timestamp).
- The plan template in `commands/draft.md` (Phase 5 Plan Structure section) and `prompt-template/plan/gen-plan-template.md` are intentionally kept in sync. When modifying either file, ensure both are updated to maintain consistency.
- Conversely, changes to `prompt-template/plan/gen-plan-template.md` must also be reflected in the Plan Structure section of `commands/draft.md`.

## Key Structure

- `commands/` -- Plugin command definitions (markdown with YAML frontmatter)
- `scripts/` -- Shell scripts for loop orchestration, Codex integration, PR management, setup
- `agents/` -- AI agent definitions (`plan-compliance-checker`, `draft-relevance-checker`)
- `prompt-template/` -- Templates for plan generation (`plan/`), Codex review (`codex/`), and hook messages (`block/`)
- `hooks/` -- Pre-tool-use hooks for plan file protection and loop state enforcement
- `tests/` -- Shell-based test suite (run individual `test-*.sh` files or all via CI)
- `docs/plans/` -- Design documents and implementation plans (pairs of `*-design.md` and `*.md`)
