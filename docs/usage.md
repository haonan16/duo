# Duo Usage Guide

Detailed usage documentation for the Duo plugin. For installation, see [Install for Claude Code](install-for-claude.md).

## How It Works

Duo creates an iterative feedback loop with two phases:

1. **Implementation Phase**: Claude works on your plan, Codex reviews summaries until COMPLETE
2. **Review Phase**: `codex review --base <branch>` checks code quality with `[P0-9]` severity markers

The loop continues until all acceptance criteria are met or no issues remain.

## Commands

| Command | Purpose |
|---------|---------|
| `/duo:start <file.md or text>` | Smart start (file path or inline text, auto-detects draft vs plan). Also generates plans with `--plan-only`. |
| `/duo:run <plan.md>` | Start iterative development with Codex review |
| `/duo:stop` | Cancel active loop |
| `/duo:pr --claude\|--codex` | Start PR review loop with bot monitoring |
| `/duo:pr-stop` | Cancel active PR loop |
| `/duo:ask [question]` | One-shot consultation with Codex |
| `/duo:setup` | Install, configure, verify prerequisites |
| `/duo:help` | Show all commands |

## Command Reference

### run

```
/duo:run [path/to/plan.md | --plan-file path/to/plan.md] [OPTIONS]

OPTIONS:
  --plan-file <path>     Explicit plan file path (alternative to positional arg)
  --max <N>              Maximum iterations before auto-stop (default: 42)
  --codex-model <MODEL:EFFORT>
                         Codex model and reasoning effort (default: gpt-5.4:xhigh)
  --codex-timeout <SECONDS>
                         Timeout for each Codex review in seconds (default: 5400)
  --track-plan-file      Indicate plan file should be tracked in git (must be clean)
  --push-every-round     Require git push after each round (default: commits stay local)
  --base-branch <BRANCH> Base branch for code review phase (default: auto-detect)
                         Priority: user input > remote default > main > master
  --full-review-round <N>
                         Interval for Full Alignment Check rounds (default: 5, min: 2)
                         Full Alignment Checks occur at rounds N-1, 2N-1, 3N-1, etc.
  --skip-impl            Skip implementation phase, go directly to code review
                         Plan file is optional when using this flag
  --claude-answer-codex  When Codex finds Open Questions, let Claude answer them
                         directly instead of asking user via AskUserQuestion
  --agent-teams          Enable Claude Code Agent Teams mode for parallel development.
                         Requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 environment variable.
                         Claude acts as team leader, splitting tasks among team members.
  -h, --help             Show help message
```

### start (plan generation mode)

When given a draft file (or inline text) with `--plan-only`, `/duo:start` acts as the plan generator:

```
/duo:start <draft.md or text> --plan-only [OPTIONS]

PLAN GENERATION OPTIONS:
  --plan-only            Generate plan and stop (do not start development loop)
  --draft-only           Alias for --plan-only (backward compatibility)
  --skip-review          Generate plan only, skip Codex refinement loop
  --max <N>              Maximum refinement rounds (default: 5)
  --codex-model <MODEL:EFFORT>
                         Codex model and reasoning effort (default: gpt-5.4:xhigh)
  --codex-timeout <SECONDS>
                         Timeout for each Codex review in seconds (default: 5400)
```

Generates an implementation plan from a draft document (Round 0). By default, iteratively refines the plan with Codex review (Round 1+) until Codex outputs APPROVED or max rounds are reached. Use `--skip-review` to generate the plan without Codex refinement.

### pr

```
/duo:pr --claude|--codex [OPTIONS]

BOT FLAGS (at least one required):
  --claude   Monitor reviews from claude[bot] (trigger with @claude)
  --codex    Monitor reviews from chatgpt-codex-connector[bot] (trigger with @codex)

OPTIONS:
  --max <N>              Maximum iterations before auto-stop (default: 42)
  --codex-model <MODEL:EFFORT>
                         Codex model and reasoning effort (default: gpt-5.4:medium)
  --codex-timeout <SECONDS>
                         Timeout for each Codex review in seconds (default: 900)
  -h, --help             Show help message
```

The PR loop automates the process of handling GitHub PR reviews from remote bots:

1. Detects the PR associated with the current branch
2. Fetches review comments from the specified bot(s)
3. Claude analyzes and fixes issues identified by the bot(s)
4. Pushes changes and triggers re-review by commenting @bot
5. Stop Hook polls for new bot reviews (every 30s, 15min timeout per bot)
6. Local Codex validates if remote concerns are approved or have issues
7. Loop continues until all bots approve or max iterations reached

**Prerequisites:**
- GitHub CLI (`gh`) must be installed and authenticated
- Codex CLI must be installed
- Current branch must have an associated open PR

### ask-codex

```
/duo:ask [OPTIONS] <question or task>

OPTIONS:
  --codex-model <MODEL:EFFORT>
                         Codex model and reasoning effort (default: gpt-5.4:xhigh)
  --codex-timeout <SECONDS>
                         Timeout for the Codex query in seconds (default: 3600)
  -h, --help             Show help message
```

The ask-codex skill sends a one-shot question or task to Codex and returns the response
inline. Unlike the development loop, this is a single consultation without iteration -- useful
for getting a second opinion, reviewing a design, or asking domain-specific questions.

Responses are saved to `.duo/skill/<timestamp>/` with `input.md`, `output.md`,
and `metadata.md` for reference.

## Monitoring

The monitor CLI is auto-installed on first `/duo:start`. Use it in a separate terminal:

```bash
# Monitor development loop progress
~/.duo/bin/duo monitor

# Monitor PR loop progress
~/.duo/bin/duo monitor --pr
```

To use `duo monitor` without the full path, run `/duo:setup` which adds `~/.duo/bin` to your PATH. After that:

```bash
duo monitor
duo monitor --pr
```

Progress data is stored in `.duo/rlcr/<timestamp>/` for each loop session.

## Cancellation

- **Development loop**: `/duo:stop`
- **PR loop**: `/duo:pr-stop`

## Environment Variables

### DUO_CODEX_BYPASS_SANDBOX

**WARNING: This is a dangerous option that disables security protections. Use only if you understand the implications.**

- **Purpose**: Controls whether Codex runs with sandbox protection
- **Default**: Not set (uses `--full-auto` with sandbox protection)
- **Values**:
  - `true` or `1`: Bypasses Codex sandbox and approvals (uses `--dangerously-bypass-approvals-and-sandbox`)
  - Any other value or unset: Uses safe mode with sandbox

**When to use this**:
- Linux servers without landlock kernel support (where Codex sandbox fails)
- Automated CI/CD pipelines in trusted environments
- Development environments where you have full control

**When NOT to use this**:
- Public or shared development servers
- When reviewing untrusted code or pull requests
- Production systems
- Any environment where unauthorized system access could cause damage

**Security implications**:
- Codex will have unrestricted access to your filesystem
- Codex can execute arbitrary commands without approval prompts
- Review all code changes carefully when using this mode

**Usage example**:
```bash
# Export before starting Claude Code
export DUO_CODEX_BYPASS_SANDBOX=true

# Or set for a single session
DUO_CODEX_BYPASS_SANDBOX=true claude --plugin-dir /path/to/duo
```
