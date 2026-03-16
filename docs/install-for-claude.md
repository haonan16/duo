# Install Duo for Claude Code

## Prerequisites

- [codex](https://github.com/openai/codex) -- OpenAI Codex CLI (for review). Verify with `codex --version`.
- `jq` -- JSON processor. Verify with `jq --version`.
- `git` -- Git version control. Verify with `git --version`.

## Option 1: Git Marketplace (Recommended)

Start Claude Code and run:

```bash
# Add the marketplace
/plugin marketplace add git@github.com:duo-dev/duo.git

# Install the plugin
/plugin install duo@duo-dev
```

## Option 2: Local Development

If you have the plugin cloned locally:

```bash
claude --plugin-dir /path/to/duo
```

## Option 3: Try Experimental Features (dev branch)

The `dev` branch contains experimental features that are not yet released to `main`. To try them locally:

```bash
git clone https://github.com/duo-dev/duo.git
cd duo
git checkout dev
```

Then start Claude Code with the local plugin directory:

```bash
claude --plugin-dir /path/to/duo
```

Note: The `dev` branch may contain unstable or incomplete features. For production use, stick with Option 1 (Git Marketplace) which tracks the stable `main` branch.

## Verify Installation

After installing, you should see Duo commands available:

```
/duo:start
/duo:run
/duo:draft
/duo:plan
/duo:ask
/duo:setup
/duo:help
```

After installing, run `/duo:setup` to verify prerequisites and configure monitoring.

## Monitor Setup (Optional)

Add the monitoring helper to your shell for real-time progress tracking:

```bash
# Add to your .bashrc or .zshrc
source ~/.claude/plugins/cache/duo-dev/duo/<LATEST.VERSION>/scripts/duo.sh
```

Then use:

```bash
duo monitor        # Monitor development loop
duo monitor --pr   # Monitor PR loop
```

## Other Install Guides

- [Install for Codex](install-for-codex.md)
- [Install for Kimi](install-for-kimi.md)

## Next Steps

See the [Usage Guide](usage.md) for detailed command reference and configuration options.
