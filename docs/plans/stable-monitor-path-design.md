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
