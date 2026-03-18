# Stable Monitor Path via Wrapper Script

## Goal Description

Install a stable, version-independent wrapper script at `~/.duo/duo.sh` that dynamically resolves the latest installed Duo plugin version at source-time. Update `setup-environment.sh` to install this wrapper and migrate users from the old versioned source line to the new stable one. This eliminates the problem where `duo monitor` breaks after plugin updates because the hardcoded version path in shell RC files becomes stale.

## Acceptance Criteria

Following TDD philosophy, each criterion includes positive and negative tests for deterministic verification.

- AC-1: Wrapper script exists and resolves the latest version portably
  - Positive Tests (expected to PASS):
    - `~/.duo/duo.sh` exists after running `/duo:setup`
    - Sourcing `~/.duo/duo.sh` in bash loads the `duo` function (i.e., `type duo` succeeds)
    - Sourcing `~/.duo/duo.sh` in zsh loads the `duo` function
    - When multiple versions exist in the cache (e.g., `1.21.0/` and `1.22.0/`), the wrapper sources the latest (`1.22.0`)
    - When the plugin cache contains multiple author directories, the wrapper still finds the correct `duo.sh`
    - Version sorting works on macOS (BSD sort, no `-V` flag) and Linux (GNU sort)
  - Negative Tests (expected to FAIL):
    - When no Duo installation exists in the cache, sourcing the wrapper should print a warning to stderr and NOT define the `duo` function
    - The wrapper should not produce any stdout output (only stderr for warnings)
  - AC-1.1: The wrapper must not break shell startup if the plugin is missing or sort behaves unexpectedly -- all failure paths must be silent no-ops or stderr-only warnings

- AC-2: Setup installs the wrapper and configures shell RC files
  - Positive Tests (expected to PASS):
    - Running `setup-environment.sh --add-to-rc ~/.bashrc` creates `~/.duo/` directory, writes the wrapper to `~/.duo/duo.sh`, and adds the source line to the RC file
    - The RC file source line points to `~/.duo/duo.sh`, not the versioned `$REPO_ROOT` path
    - The source line written is `source "$HOME/.duo/duo.sh"` (not using `$REPO_ROOT`)
  - Negative Tests (expected to FAIL):
    - After setup, the RC file should NOT contain a versioned cache path like `plugins/cache/haonan16/duo/1.22.0/`
  - AC-2.1: `configure_shell()` behavior is unchanged -- it only detects RC file status and reports `ALREADY_CONFIGURED` / `NEEDS_CONFIGURE`. The wrapper installation happens in `add_to_shell_rc()`, which is called separately by `commands/setup.md`

- AC-3: Setup migrates old versioned source lines
  - Positive Tests (expected to PASS):
    - If RC file contains `source ~/.claude/plugins/cache/haonan16/duo/1.22.0/scripts/duo.sh`, setup replaces it with `source "$HOME/.duo/duo.sh"`
    - If RC file contains `source "/path/with spaces/duo.sh"` (quoted versioned path), setup replaces it
    - If RC file already has `source ~/.duo/duo.sh` or `source "$HOME/.duo/duo.sh"`, setup does not duplicate it
  - Negative Tests (expected to FAIL):
    - After migration, no versioned duo.sh source lines remain in the RC file

- AC-4: Documentation references the stable path
  - Positive Tests (expected to PASS):
    - `README.md` shows `source ~/.duo/duo.sh` (not the versioned path)
    - `docs/usage.md` monitoring section uses `source ~/.duo/duo.sh`
  - Negative Tests (expected to FAIL):
    - Documentation should not show the versioned cache path as the recommended source line
  - AC-4.1: `commands/help.md` is out of scope -- it contains no source path, only `duo monitor` usage examples

- AC-5: `commands/setup.md` continues to work with updated `setup-environment.sh`
  - Positive Tests (expected to PASS):
    - `setup.md` Phase 3 parsing of `ALREADY_CONFIGURED` / `NEEDS_CONFIGURE` output still works (output format unchanged)
    - After `--add-to-rc` is called, the wrapper file exists and the RC file has the stable source line
  - Negative Tests (expected to FAIL):
    - `setup.md` should not need changes to its output parsing logic (if it does, this AC fails and setup.md must be updated)

- AC-6: Version bump in plugin.json, marketplace.json, and README.md
  - Positive Tests (expected to PASS):
    - All three files contain the same incremented version string
    - Version format is `X.Y.Z` with no suffix
  - Negative Tests (expected to FAIL):
    - Mismatched versions across the three files

## Path Boundaries

### Upper Bound (Maximum Acceptable Scope)

The implementation creates the wrapper script, updates `setup-environment.sh` with migration logic for old source lines, updates all documentation (README, usage, help, install guides) to reference the stable path, and includes tests for the wrapper and migration logic.

### Lower Bound (Minimum Acceptable Scope)

The implementation creates the wrapper script, updates `setup-environment.sh` to install it and write the stable source line, and updates README.md and usage.md. Migration of old source lines is handled by simple replacement.

### Allowed Choices

- Can use: Portable version sorting (must work on both GNU and BSD systems -- see Implementation Notes)
- Can use: `sed` for in-place RC file migration
- Cannot use: `sort -V` alone (not available on macOS BSD sort)
- Cannot use: Modifying `scripts/duo.sh` itself -- the wrapper is a separate, independent file
- Fixed: Wrapper location is `~/.duo/duo.sh` per the draft specification

## Feasibility Hints and Suggestions

> **Note**: This section is for reference and understanding only. These are conceptual suggestions, not prescriptive requirements.

### Conceptual Approach

**Wrapper script (`~/.duo/duo.sh`) -- portable version:**
```bash
# Duo shell integration - stable wrapper
# Dynamically resolves the latest installed Duo plugin version
# Uses portable sorting (no sort -V, works on macOS BSD and Linux GNU)
_duo_real=""
_duo_latest=""
for _duo_candidate in "$HOME"/.claude/plugins/cache/*/duo/*/scripts/duo.sh; do
    [ -f "$_duo_candidate" ] || continue
    # Extract version directory name (e.g., "1.22.0")
    _duo_ver="${_duo_candidate%/scripts/duo.sh}"
    _duo_ver="${_duo_ver##*/}"
    # Simple string comparison works for dotted versions with consistent format
    if [ -z "$_duo_latest" ] || [ "$_duo_ver" \> "$_duo_latest" ]; then
        _duo_latest="$_duo_ver"
        _duo_real="$_duo_candidate"
    fi
done
if [ -n "$_duo_real" ]; then
    source "$_duo_real"
else
    echo "duo: no installation found in ~/.claude/plugins/cache/" >&2
fi
unset _duo_real _duo_latest _duo_candidate _duo_ver
```

Note: Simple string comparison (`>`) works correctly for version strings with consistent digit padding (e.g., `1.22.0` vs `1.9.0` -- "22" > "9" alphabetically is wrong). If versions like `1.9.0` vs `1.22.0` need correct ordering, a numeric comparison function should be used instead. In practice, Duo versions have been monotonically increasing with consistent formatting, so this is acceptable. The implementer may choose a more robust approach if needed.

**Migration logic in `setup-environment.sh`:**
1. Add a new function `install_wrapper()` that creates `~/.duo/` and writes the wrapper to `~/.duo/duo.sh`
2. Modify `add_to_shell_rc()` to:
   - First call `install_wrapper()`
   - Stop using `$REPO_ROOT` for the source line -- use the fixed path `$HOME/.duo/duo.sh` instead
   - Use `sed` to replace any existing versioned duo.sh source line with the stable one
   - If no existing line found, append the stable source line
3. The grep check (`grep -qF "duo.sh"`) already catches both old and new formats -- refine it to distinguish between the stable path (already done) vs versioned path (needs migration)

### Relevant References

- `scripts/setup-environment.sh` - Current setup logic with `configure_shell()` and `add_to_shell_rc()` functions
- `scripts/duo.sh` - The real shell integration script (1,590 lines, not modified)
- `commands/setup.md` - Setup command that calls `setup-environment.sh`
- `README.md` - Quick start section showing source command
- `docs/usage.md` - Monitoring section with source instructions

## Dependencies and Sequence

### Milestones

1. Create wrapper script: Write the wrapper that dynamically resolves the latest version
   - Phase A: Implement portable glob + version comparison + source logic (no `sort -V`)
   - Phase B: Test in both bash and zsh, verify graceful no-op when uninstalled
   - Phase C: Verify `BASH_SOURCE` / `$0` resolves correctly through the wrapper indirection (duo.sh uses `BASH_SOURCE[0]` to find its `DUO_SCRIPT_DIR` -- this must point to the real duo.sh, not the wrapper)

2. Update setup-environment.sh: Install wrapper and migrate RC files
   - Phase A: Add `install_wrapper()` function to create `~/.duo/` and write wrapper
   - Phase B: Modify `add_to_shell_rc()` to stop using `$REPO_ROOT` for the source line; use fixed `$HOME/.duo/duo.sh` path instead
   - Phase C: Add migration logic in `add_to_shell_rc()` to detect and replace old versioned source lines via `sed`
   - Phase D: Verify `configure_shell()` output format is unchanged (`ALREADY_CONFIGURED` / `NEEDS_CONFIGURE`) so `commands/setup.md` parsing still works
   - Depends on: Milestone 1 complete

3. Update documentation: Replace versioned paths with stable path in docs
   - Phase A: README.md, docs/usage.md
   - Phase B: Install guides (install-for-claude.md, install-for-kimi.md) if they reference the source path
   - Note: `commands/help.md` is out of scope (contains no source path)
   - Depends on: Milestone 2 complete

4. Version bump and verification
   - Depends on: Milestone 3 complete

## Implementation Notes

### Portability Requirements
- The wrapper script must NOT use `sort -V` (GNU extension, unavailable on macOS BSD sort)
- Use POSIX-compatible shell constructs: `[` instead of `[[`, `$()` instead of backticks, portable string comparison
- The wrapper runs on every shell startup -- all failure paths must be silent or stderr-only (never break terminal init)

### BASH_SOURCE Dependency
The wrapper sources the real `scripts/duo.sh` via `source "$_duo_real"`. Inside `duo.sh`, `BASH_SOURCE[0]` (or `$0` in zsh) will correctly resolve to the real `duo.sh` path, not the wrapper path. This means `DUO_SCRIPT_DIR` and all relative path resolution in `duo.sh` will work correctly through the indirection. No changes to `duo.sh` are needed.

### Multi-Author Edge Case
If two different authors both publish a plugin named `duo`, the glob `*/duo/*/scripts/duo.sh` would match both. The version comparison would intermingle their versions. This is extremely unlikely and is an acceptable limitation -- the wrapper will pick whichever has the "latest" version string.

### Code Style Requirements
- Implementation code and comments must NOT contain plan-specific terminology such as "AC-", "Milestone", "Step", "Phase", or similar workflow markers
- These terms are for plan documentation only, not for the resulting codebase
- Use descriptive, domain-appropriate naming in code instead
- All content must be in English with no emoji or CJK characters per project rules

--- Original Design Draft Start ---

# Stable Monitor Path via Wrapper Script

## Problem

`duo monitor` requires users to source `scripts/duo.sh` from the plugin's cache directory:
```
~/.claude/plugins/cache/haonan16/duo/1.22.0/scripts/duo.sh
```

This path is hard to discover (requires knowing author, plugin name, and exact version) and breaks on every plugin update since the version number in the path changes.

Currently `/duo:setup` writes the full versioned path into the user's shell RC file. After a plugin update, the old version directory may be cleaned up, breaking `duo monitor` until the user re-runs setup.

## Goal

Install a small wrapper script at a stable, version-independent path (`~/.duo/duo.sh`) that dynamically resolves the latest installed version at source-time. Users source this wrapper instead of the versioned path directly.

## Design

### Wrapper Script (`~/.duo/duo.sh`)

A small shell script installed to `~/.duo/duo.sh` that:
1. Globs for all installed versions of duo in the plugin cache
2. Selects the latest version using version sort
3. Sources the real `duo.sh` from that path
4. Prints a warning to stderr if no installation is found

### Changes to `/duo:setup`

The setup command (specifically `setup-environment.sh`) should:
1. Create `~/.duo/` directory if it doesn't exist
2. Write/overwrite `~/.duo/duo.sh` with the wrapper content
3. Update the shell RC line to `source ~/.duo/duo.sh` instead of the versioned path
4. If an old versioned source line exists in the RC file, replace it with the new stable one

### User Experience

Before:
```bash
# In ~/.bashrc (breaks on update)
source ~/.claude/plugins/cache/haonan16/duo/1.22.0/scripts/duo.sh
```

After:
```bash
# In ~/.bashrc (stable across updates)
source ~/.duo/duo.sh
```

## Constraints

- The wrapper must work in both bash and zsh
- The wrapper must not fail loudly if the plugin is uninstalled (graceful no-op)
- The wrapper must handle multiple author directories in the cache (glob should be flexible)
- The setup command must migrate users from old versioned paths to the new stable path
- No changes to duo.sh itself -- the wrapper is a separate file

--- Original Design Draft End ---
