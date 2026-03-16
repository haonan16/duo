# Install Duo Skills for Codex

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/haonan16/duo/main/scripts/remote-install.sh | bash
```

This installs `duo`, `duo-gen-plan`, and `duo-rlcr` skills into `${CODEX_HOME:-~/.codex}/skills`.

## Verify

```bash
ls "${CODEX_HOME:-$HOME/.codex}/skills"
```

Expected: `duo`, `duo-gen-plan`, `duo-rlcr`

## Options

Pass flags after `bash -s --`:

```bash
# Install for both Codex and Kimi
curl -fsSL https://raw.githubusercontent.com/haonan16/duo/main/scripts/remote-install.sh | bash -s -- --target both

# Preview without writing
curl -fsSL https://raw.githubusercontent.com/haonan16/duo/main/scripts/remote-install.sh | bash -s -- --dry-run
```

## Other Install Guides

- [Install for Claude Code](install-for-claude.md)
- [Install for Kimi](install-for-kimi.md)
