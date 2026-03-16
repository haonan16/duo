#!/bin/bash
#
# Convenience wrapper: install Duo skills for Codex target.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
"$SCRIPT_DIR/install-skill.sh" --target codex "$@"
