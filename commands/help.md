---
description: "Show all Duo commands and usage"
hide-from-slash-command-tool: "true"
---

# Duo Help

Print the following reference card to the user exactly as shown:

---

**Duo** - iterative development with AI review

| Command | Purpose |
|---------|---------|
| `/duo:start <file or text>` | Smart start (file, inline text, or auto-detect). Also generates plans. |
| `/duo:run <plan>` | Start development loop with explicit plan |
| `/duo:stop` | Cancel active development loop |
| `/duo:pr --claude\|--codex` | Start PR review loop |
| `/duo:pr-stop` | Cancel PR review loop |
| `/duo:setup` | Install, configure, verify prerequisites |
| `/duo:help` | This reference card |

**Monitor** (run in a separate terminal, auto-installed on first `/duo:start`):

```
~/.duo/bin/duo monitor          # Development loop progress
~/.duo/bin/duo monitor --pr     # PR loop progress
```

Run `/duo:setup` to add `~/.duo/bin` to PATH, then use `duo monitor` directly.

**Interrupted loop recovery:** If your session crashes mid-loop, run `/duo:run` — it detects the interrupted loop and resumes from where it left off. Run `/duo:stop` first if you want to discard it and start fresh.

**Docs:** See `docs/usage.md` for full command reference and options.
