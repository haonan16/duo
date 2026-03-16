# Duo

**Current Version: 1.17.0**

> Derived from the [GAAC (GitHub-as-a-Context)](https://github.com/SihaoLiu/gaac) project.

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
# Add duo-dev marketplace
/plugin marketplace add duo-dev/duo
# If you want to use development branch for experimental features
/plugin marketplace add duo-dev/duo#dev
# Then install duo plugin
/plugin install duo@duo-dev
```

Requires [codex CLI](https://github.com/openai/codex) for review. See the full [Installation Guide](docs/install-for-claude.md) for prerequisites and alternative setup options.

## Quick Start

1. **Generate a plan** from your draft:
   ```bash
   /duo:draft --input draft.md --output docs/plan.md
   ```

   Or use the **plan refinement loop** for iterative improvement:
   ```bash
   /duo:plan --input draft.md --output docs/plan.md
   ```

2. **Run the loop**:
   ```bash
   /duo:run docs/plan.md
   ```

3. **Monitor progress**:
   ```bash
   source <path/to/duo>/scripts/duo.sh
   duo monitor rlcr
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
