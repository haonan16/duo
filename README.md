# Duo

**Current Version: 1.27.3**

> Based on [humanize](https://github.com/humania-org/humanize). Derived from the [GAAC (GitHub-as-a-Context)](https://github.com/SihaoLiu/gaac) project.

A Claude Code plugin for iterative development with independent AI review. Write a draft, generate a plan, then let Claude implement while Codex reviews — continuously refining until all acceptance criteria are met.

## Prerequisites

- [codex CLI](https://github.com/openai/codex) -- `npm install -g @openai/codex`
- `OPENAI_API_KEY` environment variable set
- `jq` and `git` available in your PATH

See the full [Installation Guide](docs/install-for-claude.md) for details.

## Install

```bash
/plugin marketplace add haonan16/duo
/plugin install duo@haonan16
```

## Quick Start

1. **Set up once per project** (grants script permissions, installs the CLI):
   ```bash
   /duo:setup
   ```

2. **Write a draft** describing what you want to build (any markdown file works):
   ```
   # Add caching layer
   Cache API responses in Redis with a 5-minute TTL...
   ```

3. **Start development** — Duo generates a plan, then implements and reviews it:
   ```bash
   /duo:start draft.md
   ```
   Or skip the file and describe inline:
   ```bash
   /duo:start Add a caching layer for API responses
   ```

4. **Monitor progress** in a separate terminal:
   ```bash
   duo monitor
   ```

## How It Works

<p align="center">
  <img src="docs/images/rlcr-workflow.svg" alt="RLCR Workflow" width="680"/>
</p>

The loop has two phases: **Implementation** (Claude works, Codex reviews summaries) and **Code Review** (Codex checks code quality with severity markers). Issues feed back into implementation until all acceptance criteria are resolved.

Duo uses **RLCR** (Ralph-Loop with Codex Review) — Claude implements, Codex independently reviews. No blind spots, no self-review bias.

## Commands

| Command | Purpose |
|---------|---------|
| `/duo:start <draft.md>` | Generate a plan from a draft, then run the development loop |
| `/duo:start <text>` | Use inline text as the draft |
| `/duo:start --plan-only` | Generate a plan only (with Codex refinement) |
| `/duo:run <plan.md>` | Run the development loop with an existing plan |
| `/duo:stop` | Cancel the active loop |
| `/duo:setup` | Install, configure, and verify prerequisites |
| `/duo:help` | Show all commands and options |

## Monitor Dashboard

<p align="center">
  <img src="docs/images/monitor.png" alt="Duo Monitor" width="680"/>
</p>

## Documentation

- [Usage Guide](docs/usage.md) -- Commands, options, environment variables
- [Install for Claude Code](docs/install-for-claude.md) -- Full installation instructions (includes Codex skill setup)
- [Install for Kimi](docs/install-for-kimi.md) -- Kimi CLI skill setup

## License

MIT
