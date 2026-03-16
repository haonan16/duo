# Streamlined Onboarding and Simplified Workflow - Design Document

## Problem

The Duo plugin is hard to install and not easy to use. Key friction points:

1. **Installation requires multiple manual steps** per platform, with no prerequisite checking or monitor auto-configuration.
2. **The draft -> plan -> run pipeline forces users to understand intermediate steps** before they can start. Users think "I have a document, make Duo work on it" but must pick the right command with the right flags.
3. **User-facing terminology is cryptic** ("rlcr", "finalize phase") and hook error messages are raw JSON without actionable guidance.
4. **No help command** -- users must read docs to discover commands.

## Approach

Streamlined Onboarding + Simplified Workflow (Approach B): three pillars that address all user personas without breaking existing power-user workflows.

## Pillar 1: One-Command Install (`/duo:setup`)

A new `/duo:setup` command (and standalone `scripts/setup.sh` for non-Claude platforms) that:

1. **Auto-detects platform** -- checks for `claude`, `codex`, `kimi` in PATH and asks which to configure (or auto-selects if only one found).
2. **Installs skills** -- calls the existing `install-skill.sh` under the hood (no rewrite).
3. **Configures monitor** -- appends `source <path>/scripts/duo.sh` to `~/.bashrc`/`~/.zshrc` if not already present, with user confirmation.
4. **Verifies prerequisites** -- checks for `codex`, `jq`, `git`, `gh` and prints clear messages about what is missing and how to install each.
5. **Prints a getting-started cheat sheet** at the end:

```
Duo installed successfully!

Quick start:
  /duo:start draft.md     Generate plan and start development
  duo monitor              Monitor progress (new terminal)

All commands: /duo:help
```

For Claude Code specifically, the marketplace install (`/plugin install duo@duo-dev`) stays as the primary path. `/duo:setup` runs post-install to configure monitor and verify prerequisites.

## Pillar 2: Unified Entry Point (`/duo:start`)

A new `/duo:start` command that auto-detects what to do based on context:

```
/duo:start <file> [OPTIONS]
```

Decision logic:

| Input file | What happens |
|------------|-------------|
| No file, plan exists in `.duo/` | Resume the last loop (`/duo:run` on existing plan) |
| Markdown file without plan structure | Draft -> Plan -> Run (full pipeline) |
| Markdown file with valid plan structure | Run directly (`/duo:run`) |
| `--draft-only` flag | Stop after plan generation, do not start loop |
| `--review-only` flag | Skip implementation, go to code review (`--skip-impl`) |

Plan structure detection: check if the file has the required frontmatter fields (acceptance criteria, task list) that `gen-plan-template.md` produces. Simple grep, no AI call needed.

User experience:

```
> /duo:start ideas.md

Detected: draft document (no plan structure found)
Step 1/3: Generating plan from draft...
Step 2/3: Plan generated -> docs/plans/ideas-plan.md
Step 3/3: Starting development loop...

Monitor in another terminal: duo monitor
```

Existing commands stay. `/duo:run`, `/duo:draft`, `/duo:plan` all keep working for power users who want explicit control. `/duo:start` is the guided path.

Options passthrough: any option not consumed by `/duo:start` gets forwarded to the underlying command (e.g., `--max 10`, `--codex-model`, `--push-every-round`).

## Pillar 3: Better Feedback and Simplified Terminology

### 3a: Rename user-facing terminology

| Old (internal) | New (user-facing) | Where |
|---|---|---|
| `rlcr` | `loop` or omitted entirely | monitor, state dirs, docs |
| `.duo/rlcr/` | `.duo/loop/` | state directory |
| `duo monitor rlcr` | `duo monitor` | shell command |
| `duo monitor pr` | `duo monitor --pr` | shell command flag |
| "Finalize phase" | "Review phase" | stop hook messages |

Internal code can keep using `rlcr` in variable names -- only user-facing surfaces change.

### 3b: `/duo:help` command

A new command that prints a compact reference card:

```
Duo - iterative development with AI review

Commands:
  /duo:start <file>    Smart start (auto-detects draft vs plan)
  /duo:run <plan>      Start loop with explicit plan
  /duo:draft           Generate plan from draft
  /duo:plan            Generate + refine plan with Codex
  /duo:stop            Cancel active loop
  /duo:pr              Start PR review loop
  /duo:pr-stop         Cancel PR loop
  /duo:ask <question>  One-shot Codex consultation
  /duo:setup           Install and configure
  /duo:help            This message

Monitor:  duo monitor          (in another terminal)
Docs:     docs/usage.md
```

### 3c: Human-readable hook messages

When hooks block an action, instead of raw JSON, emit a clear message with actionable guidance.

Before:
```json
{"result":"block","description":"Cannot modify state file .duo/loop/state.md"}
```

After:
```
Blocked: Cannot modify .duo/loop/state.md (managed by Duo)
Tip: Use /duo:stop to cancel the active loop
```

This means updating the `description` field in hook validators to include tips -- small edits to each validator script.

## Scope and Constraints

- All existing commands (`/duo:run`, `/duo:draft`, `/duo:plan`, `/duo:stop`, `/duo:pr`, `/duo:pr-stop`, `/duo:ask`) remain unchanged. No breaking changes.
- `/duo:start`, `/duo:setup`, and `/duo:help` are additive new commands.
- User-facing terminology changes (rlcr -> loop) affect state directory paths, monitor commands, docs, and error messages. This is a breaking change for anyone with active `.duo/rlcr/` state directories -- migration note needed.
- Hook message improvements are backward-compatible (description field is already a string).
- Internal code (variable names, function names) keeps using `rlcr` to avoid unnecessary churn.

## Non-Goals

- No TUI or interactive menus.
- No command surface redesign (keeping `/duo:` prefix, not switching to subcommands).
- No changes to the hook logic itself -- only the error messages.
- No changes to the Codex review process or plan structure.
