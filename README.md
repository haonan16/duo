# Duo

**Current Version: 1.27.1**

> Based on [humanize](https://github.com/humania-org/humanize). Derived from the [GAAC (GitHub-as-a-Context)](https://github.com/SihaoLiu/gaac) project.

A Claude Code plugin that provides iterative development with independent AI review. Build with confidence through continuous feedback loops.

## What is RLCR?

**RLCR** stands for **Ralph-Loop with Codex Review**, inspired by the official ralph-loop plugin and enhanced with independent Codex review. The name also reads as **Reinforcement Learning with Code Review** -- reflecting the iterative cycle where AI-generated code is continuously refined through external review feedback.

## Core Concepts

- **Iteration over Perfection** -- Instead of expecting perfect output in one shot, Duo leverages continuous feedback loops where issues are caught early and refined incrementally.
- **One Build + One Review** -- Claude implements, Codex independently reviews. No blind spots.
- **Ralph Loop with Swarm Mode** -- Iterative refinement continues until all acceptance criteria are met. Optionally parallelize with Agent Teams.

## How It Works

<p align="center">
  <img src="docs/images/rlcr-workflow.svg" alt="RLCR Workflow" width="680"/>
</p>

The loop has two phases: **Implementation** (Claude works, Codex reviews summaries) and **Code Review** (Codex checks code quality with severity markers). Issues feed back into implementation until resolved.

## Install

```bash
/plugin marketplace add haonan16/duo
/plugin install duo@haonan16
```

Requires [codex CLI](https://github.com/openai/codex) for review. See the full [Installation Guide](docs/install-for-claude.md) for prerequisites.

## Quick Start

1. **Set up once per project** (grants script permissions and installs the CLI):
   ```bash
   /duo:setup
   ```

2. **Start development** from a draft file or inline text:
   ```bash
   /duo:start draft.md
   /duo:start Add a caching layer for API responses
   ```

3. **Monitor progress** in a separate terminal:
   ```bash
   duo monitor
   ```

### Power User Commands

For more control, use the individual commands:

- **Generate a plan only** (with Codex refinement):
  ```bash
  /duo:start draft.md --plan-only
  ```

- **Generate a plan only** without Codex refinement:
  ```bash
  /duo:start draft.md --plan-only --skip-review
  ```

- **Run the loop** with an existing plan:
  ```bash
  /duo:run docs/plan.md
  ```

- **Setup and verify** prerequisites:
  ```bash
  /duo:setup
  ```

- **Show all commands**:
  ```bash
  /duo:help
  ```

## Monitor Dashboard

<p align="center">
  <img src="docs/images/monitor.png" alt="Duo Monitor" width="680"/>
</p>

## Documentation

- [Usage Guide](docs/usage.md) -- Commands, options, environment variables
- [Install for Claude Code](docs/install-for-claude.md) -- Full installation instructions
- [Install for Codex](docs/install-for-codex.md) -- Codex skill runtime setup
- [Install for Kimi](docs/install-for-kimi.md) -- Kimi CLI skill setup

## License

MIT
