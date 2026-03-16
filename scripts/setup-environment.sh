#!/bin/bash
#
# Duo environment setup - verifies prerequisites and configures shell.
#
# Usage:
#   setup-environment.sh --check-prereqs    Check prerequisites only
#   setup-environment.sh --configure-shell  Add monitor source to shell RC
#   setup-environment.sh --detect-platform  Detect available AI platforms
#   setup-environment.sh --install-skills   Install skills for detected platforms
#
# Exit codes:
#   0 = success (all prereqs found, or action completed)
#   1 = some prereqs missing (printed to stdout)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' NC=''
fi

check_tool() {
    local name="$1"
    local install_hint="$2"
    local required="$3"  # "required" or "optional"

    if command -v "$name" >/dev/null 2>&1; then
        local version
        version="$("$name" --version 2>/dev/null | head -1 || echo "installed")"
        printf "${GREEN}OK${NC}   %-10s %s\n" "$name" "$version"
        return 0
    else
        if [[ "$required" == "required" ]]; then
            printf "${RED}MISS${NC} %-10s %s\n" "$name" "$install_hint"
        else
            printf "${YELLOW}MISS${NC} %-10s %s (optional)\n" "$name" "$install_hint"
        fi
        return 1
    fi
}

check_prereqs() {
    echo "Checking prerequisites..."
    echo ""

    local missing=0

    check_tool "git" "https://git-scm.com/downloads" "required" || missing=$((missing + 1))
    check_tool "jq" "https://jqlang.github.io/jq/download/" "required" || missing=$((missing + 1))
    check_tool "codex" "npm install -g @openai/codex" "required" || missing=$((missing + 1))
    check_tool "gh" "https://cli.github.com/ (needed for /duo:pr)" "optional" || true

    echo ""

    if [[ "$missing" -gt 0 ]]; then
        echo "Missing $missing required tool(s). Install them and re-run /duo:setup."
        return 1
    else
        echo "All required prerequisites found."
        return 0
    fi
}

detect_platform() {
    local platforms=""

    if command -v claude >/dev/null 2>&1; then
        platforms="${platforms}claude "
    fi
    if command -v codex >/dev/null 2>&1; then
        platforms="${platforms}codex "
    fi
    if command -v kimi >/dev/null 2>&1; then
        platforms="${platforms}kimi "
    fi

    if [[ -z "$platforms" ]]; then
        echo "none"
    else
        echo "$platforms"
    fi
}

configure_shell() {
    local duo_sh="$REPO_ROOT/scripts/duo.sh"
    local source_line="source \"$duo_sh\""
    local rc_files=()
    local configured=0

    # Detect shell RC files
    if [[ -f "$HOME/.zshrc" ]]; then
        rc_files+=("$HOME/.zshrc")
    fi
    if [[ -f "$HOME/.bashrc" ]]; then
        rc_files+=("$HOME/.bashrc")
    fi

    if [[ ${#rc_files[@]} -eq 0 ]]; then
        echo "NO_RC_FILES"
        return 1
    fi

    for rc in "${rc_files[@]}"; do
        if grep -qF "duo.sh" "$rc" 2>/dev/null; then
            echo "ALREADY_CONFIGURED:$rc"
            configured=$((configured + 1))
        else
            echo "NEEDS_CONFIGURE:$rc"
        fi
    done

    if [[ "$configured" -eq "${#rc_files[@]}" ]]; then
        return 0
    fi
    return 0
}

add_to_shell_rc() {
    local rc_file="$1"
    local duo_sh="$REPO_ROOT/scripts/duo.sh"
    local source_line="source \"$duo_sh\""

    if grep -qF "duo.sh" "$rc_file" 2>/dev/null; then
        echo "Already configured in $rc_file"
        return 0
    fi

    printf '\n# Duo monitor helper\n%s\n' "$source_line" >> "$rc_file"
    echo "Added to $rc_file"
}

install_skills() {
    local target="${1:-}"

    if [[ -z "$target" ]]; then
        echo "Usage: setup-environment.sh --install-skills <kimi|codex|both>"
        return 1
    fi

    "$REPO_ROOT/scripts/install-skill.sh" --target "$target"
}

# --- Main ---

case "${1:-}" in
    --check-prereqs)
        check_prereqs
        ;;
    --detect-platform)
        detect_platform
        ;;
    --configure-shell)
        configure_shell
        ;;
    --add-to-rc)
        [[ -n "${2:-}" ]] || { echo "Usage: --add-to-rc <rc-file>"; exit 1; }
        add_to_shell_rc "$2"
        ;;
    --install-skills)
        install_skills "${2:-}"
        ;;
    -h|--help)
        cat <<'EOF'
Duo environment setup

Usage:
  setup-environment.sh --check-prereqs     Check prerequisites
  setup-environment.sh --detect-platform   Detect AI platforms
  setup-environment.sh --configure-shell   Check shell RC status
  setup-environment.sh --add-to-rc <file>  Add monitor to RC file
  setup-environment.sh --install-skills <target>  Install skills
EOF
        ;;
    *)
        echo "Unknown option: ${1:-}"
        echo "Run with --help for usage"
        exit 1
        ;;
esac
