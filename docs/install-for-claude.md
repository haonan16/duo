# Install Duo for Claude Code

## Prerequisites

- [codex](https://github.com/openai/codex) -- OpenAI Codex CLI (for review). Verify with `codex --version`.
- `jq` -- JSON processor. Verify with `jq --version`.
- `git` -- Git version control. Verify with `git --version`.

## Install

Start Claude Code and run:

```bash
/plugin marketplace add haonan16/duo
/plugin install duo@haonan16
```

Then run `/duo:setup` to verify prerequisites and configure monitoring.

## Verify

You should see Duo commands available:

```
/duo:start
/duo:run
/duo:draft
/duo:plan
/duo:ask
/duo:setup
/duo:help
```

## Other Install Guides

- [Install for Codex](install-for-codex.md)
- [Install for Kimi](install-for-kimi.md)

## Next Steps

See the [Usage Guide](usage.md) for detailed command reference and configuration options.
