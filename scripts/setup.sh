#!/bin/bash
#
# Standalone Duo setup for non-Claude platforms.
# Runs prerequisite checks, skill installation, and shell configuration
# interactively from the terminal (no Claude Code needed).
#
# Usage: ./scripts/setup.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

echo "=== Duo Setup ==="
echo ""

# Phase 1: Check prerequisites
"$SCRIPT_DIR/setup-environment.sh" --check-prereqs || true
echo ""

# Phase 2: Detect and install for platforms
PLATFORMS="$("$SCRIPT_DIR/setup-environment.sh" --detect-platform)"
echo "Detected platforms: $PLATFORMS"

for platform in $PLATFORMS; do
    case "$platform" in
        codex|kimi)
            read -rp "Install Duo skills for $platform? [y/N] " answer
            if [[ "$answer" =~ ^[Yy] ]]; then
                "$SCRIPT_DIR/setup-environment.sh" --install-skills "$platform"
            fi
            ;;
    esac
done
echo ""

# Phase 3: Configure monitor
echo "Checking shell configuration..."
"$SCRIPT_DIR/setup-environment.sh" --configure-shell | while IFS= read -r line; do
    case "$line" in
        ALREADY_CONFIGURED:*)
            echo "Monitor already configured in ${line#ALREADY_CONFIGURED:}"
            ;;
        NEEDS_CONFIGURE:*)
            rc_file="${line#NEEDS_CONFIGURE:}"
            read -rp "Add Duo monitor helper to $rc_file? [y/N] " answer
            if [[ "$answer" =~ ^[Yy] ]]; then
                "$SCRIPT_DIR/setup-environment.sh" --add-to-rc "$rc_file"
            fi
            ;;
        NO_RC_FILES)
            echo "No shell RC files found (.bashrc/.zshrc)"
            ;;
    esac
done

echo ""
echo "Setup complete!"
echo ""
echo "Quick start (in Claude Code):"
echo "  /duo:start <file.md>   Generate plan and start development"
echo ""
echo "Monitor (in another terminal):"
echo "  duo monitor"
