#!/bin/bash
#
# Remote installer for Duo skills.
#
# Downloads the Duo repo to a temp directory and runs the skill installer.
# Cleans up the temp directory when done.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/haonan16/duo/main/scripts/remote-install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/haonan16/duo/main/scripts/remote-install.sh | bash -s -- --target both
#
# Options (passed through to install-skill.sh):
#   --target MODE           kimi|codex|both (default: codex)
#   --codex-skills-dir PATH Custom Codex skills directory
#   --kimi-skills-dir PATH  Custom Kimi skills directory
#   --dry-run               Preview without writing
#

set -euo pipefail

REPO_URL="https://github.com/haonan16/duo.git"
DEFAULT_TARGET="codex"

log() {
    printf '[duo-install] %s\n' "$*"
}

die() {
    printf '[duo-install] Error: %s\n' "$*" >&2
    exit 1
}

command -v git >/dev/null 2>&1 || die "git is required but not found"

tmp_dir="$(mktemp -d)"
cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

log "downloading Duo from $REPO_URL"
git clone --depth 1 --quiet "$REPO_URL" "$tmp_dir/duo" || die "failed to clone repo"

# Default to codex target if no --target flag provided
has_target=false
for arg in "$@"; do
    if [[ "$arg" == "--target" ]]; then
        has_target=true
        break
    fi
done

if [[ "$has_target" == "false" ]]; then
    set -- --target "$DEFAULT_TARGET" "$@"
fi

log "running installer"
"$tmp_dir/duo/scripts/install-skill.sh" --repo-root "$tmp_dir/duo" "$@"
