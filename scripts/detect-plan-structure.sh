#!/bin/bash
#
# Detect whether a markdown file has plan structure matching gen-plan-template.md.
#
# A valid plan must have ALL of these sections (matching the template):
#   - "## Goal Description"
#   - "## Acceptance Criteria" with at least one "AC-" entry
#   - "## Path Boundaries"
#
# Exit 0 = plan (matches template structure)
# Exit 1 = draft or invalid (missing required sections)
#
# Usage: detect-plan-structure.sh <file>
#

set -euo pipefail

FILE="${1:-}"

if [[ -z "$FILE" || ! -f "$FILE" ]]; then
    exit 1
fi

# Check for the three required sections from gen-plan-template.md
grep -q '## Goal Description' "$FILE" || exit 1
grep -q '## Acceptance Criteria' "$FILE" || exit 1
grep -q 'AC-[0-9]' "$FILE" || exit 1
grep -q '## Path Boundaries' "$FILE" || exit 1

exit 0
