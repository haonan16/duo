# Install Duo for Kimi CLI

This guide explains how to install the Duo skills for [Kimi Code CLI](https://github.com/MoonshotAI/kimi-cli).

## Overview

Duo provides three Agent Skills for kimi:

| Skill | Type | Purpose |
|-------|------|---------|
| `duo` | Standard | General guidance for all workflows |
| `duo-gen-plan` | Flow | Generate structured plan from draft |
| `duo-rlcr` | Flow | Iterative development with Codex review |

## Installation

### Quick Install (Recommended)

From the Duo repo root, run:

```bash
./scripts/install-skills-kimi.sh
```

This command will:
- Sync `duo`, `duo-gen-plan`, and `duo-rlcr` into `~/.config/agents/skills`
- Copy runtime dependencies into `~/.config/agents/skills/duo`

Common installer script (all targets):

```bash
./scripts/install-skill.sh --target kimi
```

### Manual Install

### 1. Clone or navigate to the duo repository

```bash
cd /path/to/duo
```

### 2. Copy skills and runtime bundle to kimi's skills directory

```bash
# Create the skills directory if it doesn't exist
mkdir -p ~/.config/agents/skills

# Copy all three skills
cp -r skills/duo ~/.config/agents/skills/
cp -r skills/duo-gen-plan ~/.config/agents/skills/
cp -r skills/duo-rlcr ~/.config/agents/skills/

# Copy runtime dependencies used by the skills
cp -r scripts ~/.config/agents/skills/duo/
cp -r hooks ~/.config/agents/skills/duo/
cp -r prompt-template ~/.config/agents/skills/duo/

# Hydrate runtime root placeholders inside SKILL.md files
for skill in duo duo-gen-plan duo-rlcr; do
  sed -i.bak "s|{{DUO_RUNTIME_ROOT}}|$HOME/.config/agents/skills/duo|g" \
    "$HOME/.config/agents/skills/$skill/SKILL.md"
done
```

### 3. Verify installation

```bash
# List installed skills
ls -la ~/.config/agents/skills/

# Should show:
# duo/
# duo-gen-plan/
# duo-rlcr/
```

### 4. Restart kimi (if already running)

Skills are loaded at startup. Restart kimi to pick up the new skills:

```bash
# Exit current kimi session
/exit

# Or press Ctrl-D

# Start kimi again
kimi
```

## Usage

### List available skills

```bash
/help
```

Look for the "Skills" section in the help output.

### Use the skills

#### 1. Generate plan from draft

```bash
# Start the flow (will ask for input/output paths)
/flow:duo-gen-plan

# Or load as standard skill
/skill:duo-gen-plan
```

#### 2. Start development loop

```bash
# Start with plan file
/flow:duo-rlcr path/to/plan.md

# With options
/flow:duo-rlcr path/to/plan.md --max 20 --push-every-round

# Skip implementation, go directly to code review
/flow:duo-rlcr --skip-impl

# Load as standard skill (no auto-execution)
/skill:duo-rlcr
```

#### 3. Get general guidance

```bash
/skill:duo
```

## Command Options

### Development Loop Options

| Option | Description | Default |
|--------|-------------|---------|
| `path/to/plan.md` | Plan file path | Required (unless --skip-impl) |
| `--max N` | Maximum iterations | 42 |
| `--codex-model MODEL:EFFORT` | Codex model | gpt-5.4:xhigh |
| `--codex-timeout SECONDS` | Review timeout | 5400 |
| `--base-branch BRANCH` | Base for code review | auto-detect |
| `--full-review-round N` | Full alignment check interval | 5 |
| `--skip-impl` | Skip to code review | false |
| `--push-every-round` | Push after each round | false |

### Generate Plan Options

| Option | Description | Required |
|--------|-------------|----------|
| `--input <path>` | Draft file path | Yes |
| `--output <path>` | Plan output path | Yes |

## Prerequisites

Ensure you have `codex` CLI installed:

```bash
codex --version
```

The skills will use `gpt-5.4` with `xhigh` effort level by default.

## Uninstall

To remove the skills:

```bash
rm -rf ~/.config/agents/skills/duo
rm -rf ~/.config/agents/skills/duo-gen-plan
rm -rf ~/.config/agents/skills/duo-rlcr
```

## Troubleshooting

### Skills not showing up

1. Check the skills directory exists:
   ```bash
   ls ~/.config/agents/skills/
   ```

2. Ensure SKILL.md files are present:
   ```bash
   cat ~/.config/agents/skills/duo/SKILL.md | head -5
   ```

3. Restart kimi completely

### Codex not found

The skills expect `codex` to be in your PATH. If using a proxy, ensure `~/.zprofile` is configured:

```bash
# Add to ~/.zprofile if needed
export OPENAI_API_KEY="your-api-key"
# or other proxy settings
```

### Scripts not found

If skills report missing scripts like `setup-rlcr-loop.sh`, verify:

```bash
ls -la ~/.config/agents/skills/duo/scripts
```

### Installer options

The installer supports:

```bash
./scripts/install-skill.sh --help
```

Common examples:

```bash
# Preview only
./scripts/install-skills-kimi.sh --dry-run

# Custom skills directory
./scripts/install-skills-kimi.sh --skills-dir /custom/skills/dir
```

### Output files not found

The skills save output to:
- Cache: `~/.cache/duo/<project>/<timestamp>/`
- Loop data: `.duo/rlcr/<timestamp>/`

Ensure these directories are writable.

## See Also

- [Kimi CLI Documentation](https://moonshotai.github.io/kimi-cli/)
- [Agent Skills Format](https://agentskills.io/)
- [Install for Codex](./install-for-codex.md)
- [Duo README](../README.md)
