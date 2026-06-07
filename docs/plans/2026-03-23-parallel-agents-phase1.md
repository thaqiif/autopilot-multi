# Parallel Agents Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow multiple `run.sh` instances to run simultaneously on different task files without conflicting on shared state files.

**Architecture:** Move per-instance state (PID file, loop-state, stop-signal) from global `.autopilotagent/` into the feature directory derived from the task file path (`dirname $TASKFILE`). Export `AUTOPILOTAGENT_STATE_DIR` so the stop-hook inherits the correct path via env. Add a commit serialization mutex to prevent git staging races between parallel agents.

**Tech Stack:** Bash, git

---

## File Map

| File | Change |
|---|---|
| `run.sh` | Derive `FEATURE_DIR`; set per-feature paths; export `AUTOPILOTAGENT_STATE_DIR`; introduce `$LOOP_STATE_FILE` variable; replace all hardcoded `.autopilotagent/loop-state.md` refs |
| `hooks/stop-hook.sh` | Use `AUTOPILOTAGENT_STATE_DIR` env var instead of hardcoded `.autopilotagent` |
| `hooks/git-commit` | New script — serializes git commits via mkdir mutex |
| `CHANGELOG.md` | Document changes |

---

## Task 1: Update `run.sh` — introduce path variables

**Files:**
- Modify: `run.sh:142` (remove hardcoded `PID_FILE`), `run.sh:312-344` (add feature dir block)

The current script sets `PID_FILE=".autopilotagent.pid"` at line 142 and `STOP_SIGNAL_FILE=".autopilotagent/stop-signal"` at line 344. We need to replace these with mode-aware variables set after validation.

- [ ] **Step 1: Remove the hardcoded `PID_FILE` line**

In `run.sh`, find and remove:
```bash
# PID file for signal-based shutdown
PID_FILE=".autopilotagent.pid"
```
Replace with a comment placeholder:
```bash
# PID file — set after mode/taskfile are known (see path setup block below)
PID_FILE=""
```

- [ ] **Step 2: Add the path setup block after validation (after line 312 `fi`)**

Insert immediately after the closing `fi` of the task file validation block (the one that ends with `fi` around line 312, before the instance check):

```bash
# --- Path setup: per-feature dirs for task mode, shared .autopilotagent/ for command mode ---
if [[ "$MODE" == "task" ]]; then
    FEATURE_DIR=$(dirname "$TASKFILE")
    mkdir -p "$FEATURE_DIR"
    PID_FILE="$FEATURE_DIR/run.pid"
    STOP_SIGNAL_FILE="$FEATURE_DIR/stop-signal"
    LOOP_STATE_FILE="$FEATURE_DIR/loop-state.md"
    export AUTOPILOTAGENT_STATE_DIR="$FEATURE_DIR"
else
    mkdir -p .autopilotagent
    PID_FILE=".autopilotagent/command.pid"
    STOP_SIGNAL_FILE=".autopilotagent/stop-signal"
    LOOP_STATE_FILE=".autopilotagent/loop-state.md"
    export AUTOPILOTAGENT_STATE_DIR=".autopilotagent"
fi
```

- [ ] **Step 3: Remove the old `STOP_SIGNAL_FILE` assignment**

Find and remove the standalone assignment around line 344:
```bash
# Sentinel file for stop signal from autopilotagent command
STOP_SIGNAL_FILE=".autopilotagent/stop-signal"
```
(It's now set in the block above.)

- [ ] **Step 4: Verify the instance-check block still works**

The instance check at ~line 315 uses `$PID_FILE` — confirm it reads correctly now that `$PID_FILE` is set in the new block. No code change needed, just read and confirm the variable is in scope.

- [ ] **Step 5: Verify `cleanup_on_exit` uses `$PID_FILE`**

Check line ~339: `rm -f "$PID_FILE"` — confirm it's using the variable (not hardcoded). No change needed if already using the variable.

---

## Task 2: Replace all hardcoded loop-state paths in `run.sh`

**Files:**
- Modify: `run.sh` — replace every `.autopilotagent/loop-state.md` literal with `"$LOOP_STATE_FILE"`

There are 7 occurrences. Find them all with:
```bash
grep -n 'loop-state' run.sh
```

- [ ] **Step 1: Replace the `cat >` write in command mode (~line 476)**

```bash
# Before:
cat > .autopilotagent/loop-state.md << LOOPSTATE
# After:
cat > "$LOOP_STATE_FILE" << LOOPSTATE
```

- [ ] **Step 2: Replace the `mkdir -p .autopilotagent` just before that write**

This `mkdir -p` is now redundant (the path setup block does it), but it's harmless. Leave it, or remove it — your call. If removing, just delete the line `mkdir -p .autopilotagent` that immediately precedes the `cat >`.

- [ ] **Step 3: Replace all `rm -f ".autopilotagent/loop-state.md"` occurrences**

Each one becomes `rm -f "$LOOP_STATE_FILE"`. There are ~5 of them in both command mode and task mode loops. Replace all:

```bash
# Before (all occurrences):
rm -f ".autopilotagent/loop-state.md"
# After:
rm -f "$LOOP_STATE_FILE"
```

Also fix the combined removal on ~line 511:
```bash
# Before:
rm -f "$STOP_SIGNAL_FILE" ".autopilotagent/loop-state.md"
# After:
rm -f "$STOP_SIGNAL_FILE" "$LOOP_STATE_FILE"
```

- [ ] **Step 4: Confirm no hardcoded loop-state refs remain**

```bash
grep -n 'loop-state' run.sh
```
Every result should reference `$LOOP_STATE_FILE`, not the literal string `.autopilotagent/loop-state.md`.

---

## Task 3: Update `stop-hook.sh` to use `AUTOPILOTAGENT_STATE_DIR`

**Files:**
- Modify: `hooks/stop-hook.sh:23`

- [ ] **Step 1: Replace the hardcoded STATE_FILE line**

```bash
# Before:
STATE_FILE=".autopilotagent/loop-state.md"

# After:
STATE_DIR="${AUTOPILOTAGENT_STATE_DIR:-.autopilotagent}"
STATE_FILE="$STATE_DIR/loop-state.md"
```

- [ ] **Step 2: Verify no other hardcoded `.autopilotagent/` paths exist in stop-hook.sh**

```bash
grep -n '\.autopilotagent/' hooks/stop-hook.sh
```
Should return nothing (or only comments).

---

## Task 4: Add commit serialization mutex

**Files:**
- Create: `hooks/git-commit`

This script wraps `git commit` with a `mkdir`-based mutex so parallel agents can't race on the git staging area. `mkdir` is atomic on POSIX — it either succeeds or fails instantly, with no race window.

- [ ] **Step 1: Create `hooks/git-commit`**

```bash
#!/bin/bash
#
# git-commit — Serializes git commits across parallel autopilotagent instances.
#
# Usage: hooks/git-commit [git commit args...]
#
# Acquires a project-level mutex via `mkdir` (POSIX atomic), runs
# `git commit "$@"`, then releases. Safe to call from multiple agents
# simultaneously — others wait up to 60 seconds then abort.
#
# Install: autopilotagent.md instructs Claude to use this instead of `git commit`
# when AUTOPILOTAGENT_STATE_DIR is set and other run.pid files exist.
#

set -euo pipefail

LOCK_DIR=".autopilotagent/commit-lock"
MAX_WAIT=60
waited=0

# Acquire lock (mkdir is atomic on POSIX filesystems)
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    if [[ $waited -ge $MAX_WAIT ]]; then
        echo "autopilotagent: timed out waiting for commit lock after ${MAX_WAIT}s" >&2
        exit 1
    fi
    sleep 1
    waited=$((waited + 1))
done

# Always release on exit (normal, error, or signal)
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

# Ensure .autopilotagent dir exists (mkdir -p handles race safely)
mkdir -p .autopilotagent

git commit "$@"
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x hooks/git-commit
```

- [ ] **Step 3: Verify it runs correctly in isolation**

In any git repo with staged changes:
```bash
/path/to/autopilotagent/hooks/git-commit -m "test: verify commit wrapper works"
```
Expected: commit succeeds, lock dir created and cleaned up.

---

## Task 5: Update `commands/autopilotagent.md` with parallel agent awareness

**Files:**
- Modify: `commands/autopilotagent.md` — add a parallel agents section

Find the Phase 0 pre-flight section and add after the configuration check (after `autopilotagent.json` validation):

- [ ] **Step 1: Add parallel agent awareness instructions**

Find the "### 0b. Argument Parsing" heading and insert before it:

```markdown
### 0c. Parallel Agent Awareness

Check for other running autopilotagent instances by looking for `run.pid` files in sibling feature directories:

```bash
ls docs/autopilotagent/*/run.pid 2>/dev/null
```

If other instances are running:
- **Always use `git add <specific-files>`** — never `git add -A` or `git add .`, as other agents may have staged their own changes.
- **Use `hooks/git-commit` instead of `git commit`** to serialize commits and avoid staging races. The wrapper is at `hooks/git-commit` relative to the autopilotagent install (check `~/.claude/hooks/` or the autopilotagent repo).
- **Before modifying a file**, check if it appears in recent commits on the current branch from other agents: `git log --oneline -10 -- <file>`. If another agent recently touched it, read the current file state before editing.
```

---

## Task 6: Update `CHANGELOG.md` and commit

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Add changelog entry**

Add under a new `## 2026-03-23` section at the top:

```markdown
## 2026-03-23

### Added
- **Parallel agent support (Phase 1)** - Multiple `run.sh` instances can now run simultaneously on different task files. Per-feature state files (PID, loop-state, stop-signal) are stored in the feature's directory (`docs/autopilotagent/<feature>/`) instead of the shared `.autopilotagent/` root.
- **`AUTOPILOTAGENT_STATE_DIR` env var** - `run.sh` exports this so the stop-hook finds the correct loop-state file when multiple instances run in parallel. Falls back to `.autopilotagent/` for command mode.
- **`hooks/git-commit` commit mutex** - Thin wrapper around `git commit` that serializes commits via `mkdir` lock (POSIX atomic). Prevents staging-area races when parallel agents commit simultaneously.
- **Parallel awareness in `autopilotagent.md`** - Agents check for sibling `run.pid` files and follow safe git practices (specific file adds, serialized commits) when running in parallel.

### Changed
- **`CLAUDE.md`** - Added superpowers skill output conventions (plans → `docs/plans/`).
```

- [ ] **Step 2: Stage and commit all changes**

```bash
git add run.sh hooks/stop-hook.sh hooks/git-commit commands/autopilotagent.md CHANGELOG.md CLAUDE.md
git commit -m "feat: parallel agent support phase 1 — per-feature state files and commit mutex"
```

---

## Verification

After all tasks are complete, verify manually:

1. **Single instance still works** — Run `./run.sh docs/autopilotagent/some-feature/tasks.json` and confirm it starts normally, creates `docs/autopilotagent/some-feature/run.pid`, and the stop-hook still loops correctly.

2. **Second instance on different feature is allowed** — Open a second terminal, run `./run.sh docs/autopilotagent/other-feature/tasks.json`. Confirm it starts without the "another instance is running" error.

3. **Second instance on same feature is blocked** — Try running `./run.sh docs/autopilotagent/some-feature/tasks.json` in a third terminal while the first is running. Confirm it errors with the PID message.

4. **Command mode unchanged** — Run `./run.sh /some-command --max 2` and confirm it still uses `.autopilotagent/command.pid` and works as before.
