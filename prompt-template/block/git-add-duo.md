# Git Add Blocked: .duo Protection

The `.duo/` directory contains local loop state that should NOT be committed.
This directory is already listed in `.gitignore`.

Your command was blocked because it would add .duo files to version control.

## Allowed Commands

Use specific file paths instead of broad patterns:

    git add <specific-file>
    git add src/
    git add -p  # patch mode

## Blocked Commands

These commands are blocked when .duo exists:

    git add .duo      # direct reference
    git add -A             # adds all including .duo
    git add --all          # adds all including .duo
    git add .              # may include .duo if not gitignored
    git add -f .           # force bypasses gitignore

## Adding .duo to .gitignore

If you need to add `.duo*` to `.gitignore`, follow these steps:

1. Edit `.gitignore` to append `.duo*`
2. Run: `git add .gitignore`
3. Run: `git commit -m "Add duo local folder into gitignore"`

IMPORTANT: The commit message must NOT contain the literal string ".duo" to avoid triggering this protection.
