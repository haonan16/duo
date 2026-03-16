# Rename Humanize to Duo Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename the plugin from "humanize" to "duo" with short command names, updating all 85 files across the codebase in a single pass.

**Architecture:** Five tasks organized by operation type: file/directory renames, command name replacements, identity replacements, CLAUDE.md sync rule update, and version bump with verification. Each task is atomic and testable.

**Tech Stack:** git mv for renames, sed/Edit for content, existing shell test suite for verification.

---

## Task 1: Rename files and directories

All file and directory renames via `git mv`. No content changes in this task.

**Step 1: Rename command files**

```bash
cd /net/holy-isilon/ifs/rc_labs/ydu_lab/Lab/haonan/claude_plugin/humanize
git mv commands/start-rlcr-loop.md commands/run.md
git mv commands/cancel-rlcr-loop.md commands/stop.md
git mv commands/start-plan-loop.md commands/plan.md
git mv commands/gen-plan.md commands/draft.md
git mv commands/start-pr-loop.md commands/pr.md
git mv commands/cancel-pr-loop.md commands/pr-stop.md
```

**Step 2: Rename skill directories**

```bash
git mv skills/humanize skills/duo
git mv skills/humanize-rlcr skills/duo-rlcr
git mv skills/humanize-gen-plan skills/duo-gen-plan
```

**Step 3: Rename script file**

```bash
git mv scripts/humanize.sh scripts/duo.sh
```

**Step 4: Rename block template files**

```bash
git mv prompt-template/block/git-add-humanize.md prompt-template/block/git-add-duo.md
git mv prompt-template/block/git-not-clean-humanize-local.md prompt-template/block/git-not-clean-duo-local.md
```

**Step 5: Rename test file**

```bash
git mv tests/test-humanize-escape.sh tests/test-duo-escape.sh
```

**Step 6: Verify renames**

Run: `ls commands/ && ls skills/ && ls scripts/duo.sh && ls prompt-template/block/git-add-duo.md`
Expected: All new paths exist, no old paths remain.

**Step 7: Commit**

```bash
git add -A
git commit -m "refactor: rename files and directories from humanize to duo"
```

---

## Task 2: Replace command names in all file content

Replace the old long command names with new short names across all files. These are NOT simple find-replace of "humanize" -- they are semantic command name changes.

**Replacement map** (order matters -- longer patterns first to avoid partial matches):

| Old pattern | New pattern |
|-------------|-------------|
| `start-rlcr-loop` | `run` |
| `cancel-rlcr-loop` | `stop` |
| `start-plan-loop` | `plan` |
| `gen-plan` | `draft` |
| `start-pr-loop` | `pr` |
| `cancel-pr-loop` | `pr-stop` |

**Step 1: Replace command names and agent namespaces in command files**

Edit each renamed command file to update internal cross-references. Two patterns to replace:
- Command invocations: `/humanize:start-rlcr-loop` → `/duo:run`, etc.
- Agent namespace: `humanize:plan-compliance-checker` → `duo:plan-compliance-checker`, `humanize:draft-relevance-checker` → `duo:draft-relevance-checker`

Files to edit:
- `commands/run.md` -- line 41: `humanize:plan-compliance-checker` → `duo:plan-compliance-checker`, plus command refs
- `commands/stop.md` -- replace references to other commands
- `commands/plan.md` -- line 69: `humanize:draft-relevance-checker` → `duo:draft-relevance-checker`, plus command refs
- `commands/draft.md` -- line 57: `humanize:draft-relevance-checker` → `duo:draft-relevance-checker`, plus command refs
- `commands/pr.md` -- replace references to other commands
- `commands/pr-stop.md` -- replace references to other commands, `.humanize/` state dir refs

**Step 2: Replace command names in hooks**

Files to edit (use grep to find and replace each pattern):
- `hooks/hooks.json` -- update description
- `hooks/loop-codex-stop-hook.sh` -- all command name references
- `hooks/pr-loop-stop-hook.sh` -- all command name references
- `hooks/loop-plan-file-validator.sh` -- references to gen-plan/start-rlcr-loop
- `hooks/loop-bash-validator.sh`
- `hooks/loop-write-validator.sh`
- `hooks/loop-edit-validator.sh`
- `hooks/loop-read-validator.sh`
- `hooks/loop-post-bash-hook.sh`
- `hooks/lib/loop-common.sh`

**Step 3: Replace command names in scripts**

Files to edit:
- `scripts/duo.sh` (was humanize.sh)
- `scripts/setup-rlcr-loop.sh`
- `scripts/setup-pr-loop.sh`
- `scripts/cancel-rlcr-loop.sh`
- `scripts/cancel-pr-loop.sh`
- `scripts/ask-codex.sh`
- `scripts/validate-gen-plan-io.sh`
- `scripts/install-skill.sh`
- `scripts/install-skills-codex.sh`
- `scripts/install-skills-kimi.sh`
- `scripts/rlcr-stop-gate.sh`
- `scripts/lib/monitor-common.sh`
- `scripts/lib/monitor-skill.sh`

**Step 4: Replace command names in prompt templates**

Files to edit -- block templates with hardcoded `/humanize:` user-facing commands:
- `prompt-template/block/plan-file-modified.md` -- contains `/humanize:cancel-rlcr-loop` and `/humanize:start-rlcr-loop`
- `prompt-template/block/git-push.md` -- contains `/humanize:start-rlcr-loop`
- `prompt-template/block/schema-outdated.md` -- contains `/humanize:cancel-rlcr-loop` and references "humanize plugin"
- `prompt-template/block/git-add-duo.md` (was git-add-humanize.md) -- references to state directories
- `prompt-template/block/git-not-clean-duo-local.md` -- references to state directories
- `prompt-template/block/pr-loop-state-modification.md` -- may reference command names
- `prompt-template/block/pr-loop-prompt-write.md` -- may reference command names
- All other files in `prompt-template/block/` -- check and update any remaining command name references

Other template directories:
- All files in `prompt-template/claude/` that reference command names
- All files in `prompt-template/codex/` that reference command names
- `prompt-template/codex/full-alignment-review.md` -- references to humanize
- All files in `prompt-template/pr-loop/` that reference command names

**Step 5: Replace command names in skill files**

Files to edit:
- `skills/duo/SKILL.md`
- `skills/duo-rlcr/SKILL.md`
- `skills/duo-gen-plan/SKILL.md`
- `skills/ask-codex/SKILL.md`

**Step 6: Replace command names in agents**

Files to edit:
- `agents/plan-compliance-checker.md`
- `agents/draft-relevance-checker.md`

**Step 7: Replace command names in tests**

All test files in `tests/` and `tests/robustness/` that reference command names. Key files:
- `tests/test-start-plan-loop.sh` -- references to start-plan-loop, gen-plan
- `tests/test-gen-plan.sh` -- references to gen-plan
- `tests/test-ask-codex.sh` -- references to ask-codex
- `tests/run-all-tests.sh`
- All other test files that reference command names

**Step 8: Replace command names in docs**

Files to edit:
- `README.md`
- `docs/usage.md`
- `docs/install-for-claude.md` -- verified commands list, install instructions
- `docs/install-for-codex.md` -- skill names and install paths (currently references `humanize` skill names)
- `docs/install-for-kimi.md` -- skill names and install paths (currently references `humanize` skill names and runtime paths)

**Step 9: Replace command names in project config**

- `.claude/CLAUDE.md`
- `.github/workflows/plan-file-test.yml`

**Step 10: Verify no old command names remain**

Run: `grep -r "start-rlcr-loop\|cancel-rlcr-loop\|start-plan-loop\|start-pr-loop\|cancel-pr-loop" --include="*.md" --include="*.sh" --include="*.json" --include="*.yml" . | grep -v "docs/plans/" | grep -v ".git/"`
Expected: No matches (plan docs may still reference old names in historical context, that is acceptable).

Also verify agent namespace is updated:
Run: `grep -r "humanize:" --include="*.md" --include="*.sh" . | grep -v "docs/plans/" | grep -v ".git/"`
Expected: No matches. All `humanize:` prefixed references (commands and agents) should now be `duo:`.

Note: `gen-plan` and `ask-codex` appear in script filenames (`validate-gen-plan-io.sh`, `ask-codex.sh`) and as the skill directory name (`skills/ask-codex/`). These script/directory names do NOT need renaming -- they are internal implementation details, not user-facing command names. Only the user-facing command invocations (e.g., `/humanize:gen-plan` or `/duo:draft`) need to change.

**Step 11: Commit**

```bash
git add -A
git commit -m "refactor: replace old command names with new short names"
```

---

## Task 3: Replace plugin identity strings

Replace all occurrences of "humanize" (as plugin/brand name), "humania"/"humania-org" (as org name), environment variables, and state directory patterns.

**Replacement map:**

| Old | New | Context |
|-----|-----|---------|
| `"name": "humanize"` | `"name": "duo"` | plugin.json, marketplace.json |
| `"name": "humania"` | `"name": "duo-dev"` | marketplace.json owner |
| `"humania-org"` | `"duo-dev"` | author name, repo URLs |
| `humania-org/humanize` | `duo-dev/duo` | repo/homepage URLs |
| `humanize@humania` | `duo@duo-dev` | install commands |
| `Humanize` (title case) | `Duo` | descriptions, headings, comments |
| `humanize` (lower case) | `duo` | plugin name, state dirs, references |
| `HUMANIZE_` (env var prefix) | `DUO_` | environment variables |
| `{{HUMANIZE_RUNTIME_ROOT}}` | `{{DUO_RUNTIME_ROOT}}` | skill template placeholder |
| `.humanize` | `.duo` | state directory pattern in .gitignore and scripts |

**Step 1: Update plugin config files**

Edit `.claude-plugin/plugin.json`:
- `"name": "humanize"` → `"name": "duo"`
- `"description": "Humanize - An iterative..."` → `"description": "Duo - An iterative..."`
- `"author": {"name": "humania-org"}` → `"author": {"name": "duo-dev"}`
- `"repository": "https://github.com/humania-org/humanize"` → `"repository": "https://github.com/duo-dev/duo"`
- `"homepage": "https://github.com/humania-org/humanize#readme"` → `"homepage": "https://github.com/duo-dev/duo#readme"`

Edit `.claude-plugin/marketplace.json`:
- `"name": "humania"` → `"name": "duo-dev"`
- `"owner": {"name": "humania-org"}` → `"owner": {"name": "duo-dev"}`
- `"name": "humanize"` → `"name": "duo"`
- `"description": "Humanize - An iterative..."` → `"description": "Duo - An iterative..."`

**Step 2: Update .gitignore**

Change `.humanize*` → `.duo*` and update the comment above it.

**Step 3: Update .claude/CLAUDE.md**

Replace `Humanize` with `Duo` in the heading and description. Update command references (already done in Task 2, but verify identity strings too).

**Step 4: Update environment variables and hardcoded paths in scripts**

All scripts containing `HUMANIZE_` prefix env vars:
- `scripts/duo.sh` -- `HUMANIZE_SCRIPT_DIR` → `DUO_SCRIPT_DIR`, `HUMANIZE_HOOKS_LIB_DIR` → `DUO_HOOKS_LIB_DIR`
- `scripts/rlcr-stop-gate.sh` -- `HUMANIZE_ROOT` → `DUO_ROOT`
- `scripts/ask-codex.sh` -- `HUMANIZE_CODEX_BYPASS_SANDBOX` → `DUO_CODEX_BYPASS_SANDBOX`, also `.humanize/skill/` state path → `.duo/skill/`
- `scripts/install-skill.sh` -- critical hardcodings:
  - `HUMANIZE_RUNTIME_ROOT` template var
  - Line 6 comment: `skills/{humanize,humanize-gen-plan,humanize-rlcr}` → `skills/{duo,duo-gen-plan,duo-rlcr}`
  - Line 7 comment: `<skills-dir>/humanize/{scripts,hooks,prompt-template}` → `<skills-dir>/duo/...`
  - Line 14 comment: "Humanize repo root" → "Duo repo root"
  - `install_runtime_bundle()`: `local runtime_root="$target_dir/humanize"` → `"$target_dir/duo"` (lines 113, 125)
  - `sync_one_skill()` calls with old skill names if hardcoded
- `scripts/install-skills-codex.sh` -- any hardcoded skill names or paths
- `scripts/install-skills-kimi.sh` -- any hardcoded skill names or paths

**Step 5: Update template placeholder in skill files**

All skill SKILL.md files: `{{HUMANIZE_RUNTIME_ROOT}}` → `{{DUO_RUNTIME_ROOT}}`
- `skills/duo/SKILL.md`
- `skills/duo-rlcr/SKILL.md`
- `skills/duo-gen-plan/SKILL.md`
- `skills/ask-codex/SKILL.md`

**Step 6: Update skill name fields**

- `skills/duo/SKILL.md`: `name: humanize` → `name: duo`
- `skills/duo-rlcr/SKILL.md`: `name: humanize-rlcr` → `name: duo-rlcr`
- `skills/duo-gen-plan/SKILL.md`: `name: humanize-gen-plan` → `name: duo-gen-plan`

**Step 7: Update state directory references**

Search all hooks, scripts, and templates for `.humanize/` and replace with `.duo/`. Key files:
- `hooks/loop-codex-stop-hook.sh`
- `hooks/pr-loop-stop-hook.sh`
- `hooks/loop-write-validator.sh`
- `hooks/loop-edit-validator.sh`
- `hooks/loop-bash-validator.sh`
- `hooks/loop-read-validator.sh`
- `hooks/loop-post-bash-hook.sh`
- `hooks/lib/loop-common.sh`
- `scripts/setup-rlcr-loop.sh`
- `scripts/setup-pr-loop.sh`
- `scripts/cancel-rlcr-loop.sh`
- `scripts/cancel-pr-loop.sh`
- `scripts/ask-codex.sh`
- `prompt-template/block/git-add-duo.md` (was git-add-humanize.md)
- `prompt-template/block/git-not-clean-duo-local.md`

**Step 8: Update remaining "humanize"/"Humanize" in all content**

Sweep across ALL remaining files for any `humanize` or `Humanize` references and replace with `duo` or `Duo`. This catches:
- README.md title and descriptions
- docs/usage.md descriptions
- docs/install-for-claude.md, install-for-codex.md, install-for-kimi.md
- hooks/hooks.json description field
- All prompt templates referencing "Humanize"
- All test files referencing "humanize" in comments, variable names, or assertions
- Monitor function names (`humanize()` function in duo.sh)

**Step 9: Verify no old identity strings remain**

Run: `grep -ri "humanize\|humania" --include="*.md" --include="*.sh" --include="*.json" --include="*.yml" . | grep -v "docs/plans/" | grep -v ".git/" | grep -v "test-duo-escape.sh"`
Expected: No matches outside plan docs. The test-duo-escape.sh file name is fine (it was renamed in Task 1).

Note: `docs/plans/` files (design docs and implementation plans) may still reference "humanize" in historical context. This is acceptable -- they document what was changed, not what is current.

**Step 10: Commit**

```bash
git add -A
git commit -m "refactor: replace humanize identity with duo across all files"
```

---

## Task 4: Update CLAUDE.md sync rule

The `.claude/CLAUDE.md` file has a rule that `commands/gen-plan.md` and `prompt-template/plan/gen-plan-template.md` must stay in sync. Since `gen-plan.md` was renamed to `draft.md`, this rule needs updating.

**Step 1: Update the sync rule**

Edit `.claude/CLAUDE.md` to change:
- `commands/gen-plan.md` → `commands/draft.md`
- Keep the reference to `prompt-template/plan/gen-plan-template.md` unchanged (that file was not renamed)

The two lines to update are:
- "The plan template in `commands/gen-plan.md` (Phase 5 Plan Structure section) and `prompt-template/plan/gen-plan-template.md` are intentionally kept in sync."
- "Conversely, changes to `prompt-template/plan/gen-plan-template.md` must also be reflected in the Plan Structure section of `commands/gen-plan.md`."

**Step 2: Verify**

Read `.claude/CLAUDE.md` and confirm it references `commands/draft.md` not `commands/gen-plan.md`.

**Step 3: Commit**

```bash
git add .claude/CLAUDE.md
git commit -m "refactor: update CLAUDE.md sync rule for renamed draft command"
```

---

## Task 5: Version bump + full verification

**Step 1: Bump version to 1.16.0**

Edit these three files:
- `.claude-plugin/plugin.json`: `"version": "1.15.0"` → `"version": "1.16.0"`
- `.claude-plugin/marketplace.json`: `"version": "1.15.0"` → `"version": "1.16.0"`
- `README.md`: `Current Version: 1.15.0` → `Current Version: 1.16.0`

**Step 2: Update test files for new names**

The test files reference old command file names. Update:
- `tests/test-start-plan-loop.sh` → this file tests `commands/start-plan-loop.md` which is now `commands/plan.md`. Update ALL path references inside the test:
  - `$COMMANDS_DIR/start-plan-loop.md` → `$COMMANDS_DIR/plan.md`
  - `"start-plan-loop"` naming convention test → `"plan"`
  - Any string `start-plan-loop` in test descriptions → `plan`
- `tests/test-gen-plan.sh` → update references from `gen-plan.md` to `draft.md`, from `gen-plan` naming checks to `draft`

**Step 3: Run the plan loop test suite**

Run: `bash tests/test-start-plan-loop.sh 2>&1`
Expected: All tests PASS.

**Step 4: Run the gen-plan (now draft) test suite**

Run: `bash tests/test-gen-plan.sh 2>&1`
Expected: All tests PASS.

**Step 5: Run the full test suite if available**

Run: `bash tests/run-all-tests.sh 2>&1 || true`
Check output for any failures related to the rename.

**Step 6: Final grep verification**

Run: `grep -ri "humanize\|humania" --include="*.md" --include="*.sh" --include="*.json" --include="*.yml" . | grep -v "docs/plans/" | grep -v ".git/"`
Expected: No matches.

Run: `grep -r "start-rlcr-loop\|cancel-rlcr-loop\|start-plan-loop\|start-pr-loop\|cancel-pr-loop" --include="*.md" --include="*.sh" --include="*.json" --include="*.yml" . | grep -v "docs/plans/" | grep -v ".git/"`
Expected: No matches.

**Step 7: Commit**

```bash
git add -A
git commit -m "chore: bump version to 1.16.0 for duo rename"
```

---

## Summary

| Task | Description | Type | Depends On |
|------|-------------|------|------------|
| 1 | Rename files and directories | git mv | - |
| 2 | Replace command names in content | Content edit | Task 1 |
| 3 | Replace plugin identity strings | Content edit | Task 1 |
| 4 | Update CLAUDE.md sync rule | Content edit | Task 2 |
| 5 | Version bump + full verification | Edit + test | Tasks 1-4 |

Tasks 2 and 3 can run in parallel after Task 1. Task 4 depends on Task 2. Task 5 depends on all.
