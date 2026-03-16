# Public Release Preparation Design

## Overview

Prepare the Duo repo for public release under the `haonan16` GitHub account. Replace all `duo-dev` org references with `haonan16`, add a LICENSE file, fix SSH-only install URLs to use HTTPS, and bump version.

## Changes

1. Add MIT LICENSE file (declared in plugin.json but missing)
2. Replace `duo-dev` with `haonan16` in all user-facing files (skip docs/plans/ historical records)
3. Fix SSH URL in install docs to HTTPS for public access
4. Version bump per project rules

## Files Affected

- Create: `LICENSE`
- Modify: `.claude-plugin/plugin.json` (author, repository, homepage)
- Modify: `.claude-plugin/marketplace.json` (owner name)
- Modify: `README.md` (install commands)
- Modify: `docs/install-for-claude.md` (install commands, clone URL, monitor path)
- Modify: `docs/install-for-codex.md` (clone URL)
- Modify: `docs/usage.md` (monitor source path)
- Modify: Version files (plugin.json, marketplace.json, README.md)

## Out of Scope

- Actual GitHub repo creation/rename
- docs/plans/ files (historical)