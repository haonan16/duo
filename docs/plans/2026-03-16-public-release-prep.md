# Public Release Preparation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Prepare the Duo repo for public release under the `haonan16` GitHub account.

**Architecture:** Simple find-and-replace of `duo-dev` -> `haonan16` across user-facing files, add LICENSE, fix SSH URLs, bump version.

**Tech Stack:** Markdown, JSON, shell

---

## Task 1: Add MIT LICENSE file

**Files:**
- Create: `LICENSE`

**Step 1: Create the LICENSE file**

Standard MIT license with current year and author.

**Step 2: Commit**

```bash
git add LICENSE
git commit -m "chore: add MIT LICENSE file"
```

---

## Task 2: Replace duo-dev with haonan16 in plugin metadata

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

**Step 1: Update plugin.json**

- `"name": "duo-dev"` in author -> `"name": "haonan16"`
- `"repository": "https://github.com/duo-dev/duo"` -> `"https://github.com/haonan16/duo"`
- `"homepage": "https://github.com/duo-dev/duo#readme"` -> `"https://github.com/haonan16/duo#readme"`

**Step 2: Update marketplace.json**

- `"name": "duo-dev"` (top-level) -> `"name": "haonan16"`
- `"name": "duo-dev"` (owner) -> `"name": "haonan16"`

**Step 3: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore: update plugin metadata org from duo-dev to haonan16"
```

---

## Task 3: Update install docs and README

**Files:**
- Modify: `README.md`
- Modify: `docs/install-for-claude.md`
- Modify: `docs/install-for-codex.md`
- Modify: `docs/usage.md`

**Step 1: Update README.md install commands**

- `duo-dev/duo` -> `haonan16/duo` (marketplace add)
- `duo-dev/duo#dev` -> `haonan16/duo#dev`
- `duo@duo-dev` -> `duo@haonan16`

**Step 2: Update docs/install-for-claude.md**

- SSH URL `git@github.com:duo-dev/duo.git` -> HTTPS `https://github.com/haonan16/duo`
- `duo@duo-dev` -> `duo@haonan16`
- `https://github.com/duo-dev/duo.git` -> `https://github.com/haonan16/duo.git`
- Monitor path `duo-dev/duo` -> `haonan16/duo`

**Step 3: Update docs/install-for-codex.md**

- `https://github.com/duo-dev/duo.git` -> `https://github.com/haonan16/duo.git`

**Step 4: Update docs/usage.md**

- Monitor path `duo-dev/duo` -> `haonan16/duo`

**Step 5: Commit**

```bash
git add README.md docs/install-for-claude.md docs/install-for-codex.md docs/usage.md
git commit -m "docs: update org references from duo-dev to haonan16 for public release"
```

---

## Task 4: Version bump and verify

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

**Step 1: Bump version from 1.17.0 to 1.18.0**

**Step 2: Run tests to verify**

```bash
bash tests/test-start-plan-loop.sh 2>&1
bash tests/test-gen-plan.sh 2>&1
```

**Step 3: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json README.md
git commit -m "chore: bump version to 1.18.0 for public release preparation"
```
