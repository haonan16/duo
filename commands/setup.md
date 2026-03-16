---
description: "Install, configure, and verify Duo prerequisites"
allowed-tools:
  - "Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh:*)"
  - "AskUserQuestion"
hide-from-slash-command-tool: "true"
---

# Duo Setup

Guide the user through setting up Duo. Run each phase in order.

## Phase 1: Check Prerequisites

Run the prerequisite check:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh" --check-prereqs
```

Report the results to the user. If required tools are missing, show install instructions and ask if they want to continue anyway or install first.

## Phase 2: Detect Platform

Run platform detection:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh" --detect-platform
```

Parse the output:
- If running inside Claude Code (this session), report: "You are using Claude Code. The plugin is already active."
- If `codex` or `kimi` are detected, ask if the user wants to install skills for those platforms:

Use AskUserQuestion:
- Question: "Detected additional platforms. Install Duo skills for them?"
- Options based on which platforms were detected (codex, kimi, or both)
- Include a "Skip" option

If the user chooses to install, run:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh" --install-skills <target>
```

## Phase 3: Configure Monitor

Run shell RC check:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh" --configure-shell
```

Parse each line:
- `ALREADY_CONFIGURED:<file>`: Report that monitor is already set up in that file
- `NEEDS_CONFIGURE:<file>`: Ask user if they want to add the monitor helper to that file
- `NO_RC_FILES`: Report that no shell RC files were found

If the user approves adding to a file:
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-environment.sh" --add-to-rc "<file>"
```

Report: "Monitor configured. Run `source <file>` or open a new terminal to use `duo monitor`."

## Phase 4: Print Getting Started

After all phases, print:

```
Setup complete!

Quick start:
  /duo:start <file.md>   Generate plan and start development
  duo monitor             Monitor progress (in another terminal)

All commands: /duo:help
```
