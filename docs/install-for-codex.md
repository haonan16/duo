# Install Duo Skills for Codex

This guide explains how to install the Duo skills for Codex skill runtime (`$CODEX_HOME/skills`).

## Quick Install (Recommended)

One-line install from anywhere:

```bash
tmp_dir="$(mktemp -d)" && git clone --depth 1 https://github.com/duo-dev/duo.git "$tmp_dir/duo" && "$tmp_dir/duo/scripts/install-skills-codex.sh"
```

From the Duo repo root:

```bash
./scripts/install-skills-codex.sh
```

Or use the unified installer directly:

```bash
./scripts/install-skill.sh --target codex
```

This will:
- Sync `duo`, `duo-gen-plan`, and `duo-rlcr` into `${CODEX_HOME:-~/.codex}/skills`
- Copy runtime dependencies into `${CODEX_HOME:-~/.codex}/skills/duo`
- Use RLCR defaults: `codex exec` with `gpt-5.4:xhigh`, `codex review` with `gpt-5.4:high`

## Verify

```bash
ls -la "${CODEX_HOME:-$HOME/.codex}/skills"
```

Expected directories:
- `duo`
- `duo-gen-plan`
- `duo-rlcr`

Runtime dependencies in `duo/`:
- `scripts/`
- `hooks/`
- `prompt-template/`

Installed files/directories:
- `${CODEX_HOME:-~/.codex}/skills/duo/SKILL.md`
- `${CODEX_HOME:-~/.codex}/skills/duo-gen-plan/SKILL.md`
- `${CODEX_HOME:-~/.codex}/skills/duo-rlcr/SKILL.md`
- `${CODEX_HOME:-~/.codex}/skills/duo/scripts/`
- `${CODEX_HOME:-~/.codex}/skills/duo/hooks/`
- `${CODEX_HOME:-~/.codex}/skills/duo/prompt-template/`

## Optional: Install for Both Codex and Kimi

```bash
./scripts/install-skill.sh --target both
```

## Useful Options

```bash
# Preview without writing
./scripts/install-skills-codex.sh --dry-run

# Custom Codex skills dir
./scripts/install-skills-codex.sh --codex-skills-dir /custom/codex/skills
```

## Troubleshooting

If scripts are not found from installed skills:

```bash
ls -la "${CODEX_HOME:-$HOME/.codex}/skills/duo/scripts"
```
