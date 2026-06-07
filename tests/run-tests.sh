#!/bin/bash
#
# run-tests.sh - Test suite for run.sh
#
# Usage: ./tests/run-tests.sh
#
# Zero dependencies - just bash.

# Don't use set -e, we need to capture exit codes from failing commands

# Change to repo root
cd "$(dirname "$0")/.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
TOTAL=0

# Test helper
test_it() {
    local name="$1"
    local condition="$2"
    ((TOTAL++))

    if eval "$condition"; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} $name"
        ((FAILED++))
    fi
}

# Strip ANSI color codes from output
strip_colors() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# Test helper for checking output contains string
output_contains() {
    local clean_output
    clean_output=$(strip_colors "$OUTPUT")
    [[ "$clean_output" == *"$1"* ]]
}

# Test helper for checking exit code
exited_with() {
    [[ "$EXIT_CODE" == "$1" ]]
}

make_fake_agent_bin() {
    local bindir="$1"
    local name="$2"
    local behavior="$3"
    local target_file="$4"

    cat > "$bindir/$name" << EOF
#!/bin/bash
printf '%s\n' "\$0 \$*" >> "$target_file"
case "$behavior" in
    complete_one)
        prompt="\${*: -1}"
        taskfile=\$(printf '%s\n' "\$prompt" | sed -n 's|^/autopilotagent \([^ ]*\.json\).*|\1|p' | head -1)
        if [[ -n "\$taskfile" && -f "\$taskfile" ]]; then
            tmp="\${taskfile}.tmp"
            jq '([.requirements | to_entries[] | select(.value.passes != true and .value.stuck != true and .value.invalidTest != true) | .key][0]) as \$i | .requirements[\$i].passes = true' "\$taskfile" > "\$tmp"
            mv "\$tmp" "\$taskfile"
        fi
        while true; do sleep 1; done
        ;;
    invalid_one)
        prompt="\${*: -1}"
        taskfile=\$(printf '%s\n' "\$prompt" | sed -n 's|^/autopilotagent \([^ ]*\.json\).*|\1|p' | head -1)
        if [[ -n "\$taskfile" && -f "\$taskfile" ]]; then
            tmp="\${taskfile}.tmp"
            jq '([.requirements | to_entries[] | select(.value.passes != true and .value.stuck != true and .value.invalidTest != true) | .key][0]) as \$i | .requirements[\$i].invalidTest = true' "\$taskfile" > "\$tmp"
            mv "\$tmp" "\$taskfile"
        fi
        while true; do sleep 1; done
        ;;
    wait_for_stop)
        trap 'printf "%s\n" TERM >> "$target_file"; exit 0' TERM
        while true; do sleep 1; done
        ;;
    sleep)
        while true; do sleep 1; done
        ;;
esac
EOF
    chmod +x "$bindir/$name"
}

echo "Running run.sh tests..."
echo ""

# ============================================
# Basic argument handling
# ============================================
echo "## Argument handling"

# Test: --help shows usage
OUTPUT=$(./run.sh --help 2>&1) ; EXIT_CODE=$?
test_it "--help shows usage info" 'output_contains "Usage:" && exited_with 0'

# Test: -h also works
OUTPUT=$(./run.sh -h 2>&1) ; EXIT_CODE=$?
test_it "-h also shows help" 'output_contains "Usage:" && exited_with 0'

# Test: No arguments shows error
OUTPUT=$(./run.sh 2>&1) ; EXIT_CODE=$?
test_it "no arguments shows error" 'output_contains "No task file or command specified"'

# Test: Non-existent file shows error
OUTPUT=$(./run.sh nonexistent.json 2>&1) ; EXIT_CODE=$?
test_it "non-existent file shows error" 'output_contains "not found"'

# Test: Absolute JSON path is treated as task file, not command mode
ABS_TASKFILE="$(pwd)/tests/fixtures/incomplete.json"
OUTPUT=$(./run.sh "$ABS_TASKFILE" --dry-run 2>&1)
EXIT_CODE=$?
test_it "absolute JSON path: task mode" 'output_contains "Task File:" && output_contains "$ABS_TASKFILE"'

# Test: Unknown option shows error
OUTPUT=$(./run.sh --unknown 2>&1) ; EXIT_CODE=$?
test_it "unknown option shows error" 'output_contains "Unknown option"'

echo ""

# ============================================
# Requirement counting
# ============================================
echo "## Requirement counting"

# Test: All complete exits immediately
OUTPUT=$(./run.sh tests/fixtures/all-complete.json --dry-run 2>&1)
EXIT_CODE=$?
test_it "all complete: exits immediately" 'output_contains "All requirements complete" && exited_with 0'
test_it "all complete: shows 3/3 completed" 'output_contains "Completed: 3 / 3"'
test_it "all complete: shows 0 remaining" 'output_contains "Remaining: 0"'

# Test: Empty requirements exits immediately
OUTPUT=$(./run.sh tests/fixtures/empty.json --dry-run 2>&1)
EXIT_CODE=$?
test_it "empty: exits immediately" 'output_contains "All requirements complete" && exited_with 0'
test_it "empty: shows 0/0 completed" 'output_contains "Completed: 0 / 0"'

# Test: Incomplete shows correct counts
OUTPUT=$(./run.sh tests/fixtures/incomplete.json --dry-run 2>&1)
EXIT_CODE=$?
test_it "incomplete: shows 1/3 completed" 'output_contains "Completed: 1 / 3"'
test_it "incomplete: shows 2 remaining" 'output_contains "Remaining: 2"'

# Test: Mixed stuck/invalid counts correctly
OUTPUT=$(./run.sh tests/fixtures/mixed-stuck.json --dry-run 2>&1)
EXIT_CODE=$?
test_it "mixed: shows 1/4 completed" 'output_contains "Completed: 1 / 4"'
test_it "mixed: shows 1 stuck" 'output_contains "Stuck: 1"'
test_it "mixed: shows 1 remaining (not 3)" 'output_contains "Remaining: 1"'

echo ""

# ============================================
# Dry run behavior
# ============================================
echo "## Dry run behavior"

# Test: Dry run shows what would be executed
OUTPUT=$(./run.sh tests/fixtures/incomplete.json --dry-run 2>&1)
EXIT_CODE=$?
test_it "dry-run: shows command that would run" 'output_contains "[DRY RUN] Would execute"'
test_it "dry-run: mentions claude command" 'output_contains "claude"'
test_it "dry-run: stops after simulated sessions" 'output_contains "Stopping after"'

echo ""

# ============================================
# Agent selection
# ============================================
echo "## Agent selection"

# Test: --agent codex changes the rendered command
OUTPUT=$(./run.sh tests/fixtures/incomplete.json --agent codex --dry-run 2>&1)
EXIT_CODE=$?
test_it "--agent codex: uses codex exec" 'output_contains "Agent: codex" && output_contains "codex exec --sandbox workspace-write"'

# Test: --agent opencode changes the rendered command
OUTPUT=$(./run.sh tests/fixtures/incomplete.json --agent opencode --dry-run 2>&1)
EXIT_CODE=$?
test_it "--agent opencode: uses opencode run mode" 'output_contains "Agent: opencode" && output_contains "opencode run --dangerously-skip-permissions"'

# Test: --agent cmd changes the rendered command
OUTPUT=$(./run.sh tests/fixtures/incomplete.json --agent cmd --dry-run 2>&1)
EXIT_CODE=$?
test_it "--agent cmd: uses command code headless mode" 'output_contains "Agent: cmd" && output_contains "cmd -p" && output_contains "--yolo"'

# Test: AUTOPILOTAGENT_AGENT env var is honored
OUTPUT=$(AUTOPILOTAGENT_AGENT=codex ./run.sh tests/fixtures/incomplete.json --dry-run 2>&1)
EXIT_CODE=$?
test_it "AUTOPILOTAGENT_AGENT: sets default agent" 'output_contains "Agent: codex" && output_contains "codex exec --sandbox workspace-write"'

# Test: unknown agent shows error
OUTPUT=$(./run.sh tests/fixtures/incomplete.json --agent nope --dry-run 2>&1)
EXIT_CODE=$?
test_it "--agent unknown: shows error" 'output_contains "Unknown agent" && exited_with 1'

# Test: --model is passed through to non-Claude agents
OUTPUT=$(./run.sh tests/fixtures/incomplete.json --agent codex --model gpt-5.4 --dry-run 2>&1)
EXIT_CODE=$?
test_it "--model codex: passes model flag" 'output_contains "codex exec --sandbox workspace-write --model gpt-5.4"'

OUTPUT=$(./run.sh tests/fixtures/incomplete.json --agent opencode --model openai/gpt-5.4 --dry-run 2>&1)
EXIT_CODE=$?
test_it "--model opencode: passes model flag" 'output_contains "opencode run --dangerously-skip-permissions --model openai/gpt-5.4"'

OUTPUT=$(./run.sh tests/fixtures/incomplete.json --agent cmd --model claude-sonnet-4-6 --dry-run 2>&1)
EXIT_CODE=$?
test_it "--model cmd: passes model flag" 'output_contains "cmd -p" && output_contains "--model claude-sonnet-4-6"'

echo ""

# ============================================
# Agent execution behavior
# ============================================
echo "## Agent execution behavior"

TMP_TEST_DIR=$(mktemp -d)
FAKE_BIN="$TMP_TEST_DIR/bin"
mkdir -p "$FAKE_BIN"

TASK_COPY="$TMP_TEST_DIR/incomplete.json"
cp tests/fixtures/incomplete.json "$TASK_COPY"
make_fake_agent_bin "$FAKE_BIN" codex complete_one "$TMP_TEST_DIR/codex.log"
OUTPUT=$(PATH="$FAKE_BIN:$PATH" timeout 20 ./run.sh "$TASK_COPY" --agent codex --batch 1 --delay 0 2>&1)
EXIT_CODE=$?
test_it "codex execution: launches fake binary and advances task" 'output_contains "Batch complete (1 requirement(s))" && output_contains "+ 1 requirement(s) completed" && grep -q "codex exec --sandbox workspace-write" "$TMP_TEST_DIR/codex.log"'

TASK_COPY="$TMP_TEST_DIR/invalid.json"
cp tests/fixtures/incomplete.json "$TASK_COPY"
make_fake_agent_bin "$FAKE_BIN" codex invalid_one "$TMP_TEST_DIR/codex-invalid.log"
OUTPUT=$(PATH="$FAKE_BIN:$PATH" timeout 20 ./run.sh "$TASK_COPY" --agent codex --batch 1 --delay 0 2>&1)
EXIT_CODE=$?
test_it "invalidTest execution: reports invalid-test progress" 'output_contains "Batch complete (1 requirement(s))" && output_contains "+ 1 requirement(s) invalid test"'

TASK_COPY="$TMP_TEST_DIR/stop.json"
cp tests/fixtures/incomplete.json "$TASK_COPY"
make_fake_agent_bin "$FAKE_BIN" cmd wait_for_stop "$TMP_TEST_DIR/cmd.log"
PATH="$FAKE_BIN:$PATH" ./run.sh "$TASK_COPY" --agent cmd --batch 1 --delay 0 > "$TMP_TEST_DIR/stop.out" 2>&1 &
RUN_PID=$!
sleep 2
kill -USR1 "$RUN_PID" 2>/dev/null || true
wait "$RUN_PID" 2>/dev/null
OUTPUT=$(cat "$TMP_TEST_DIR/stop.out" 2>/dev/null)
EXIT_CODE=$?
test_it "agent stop: terminates fake command-code process" 'output_contains "Stop signal received" && grep -q "TERM" "$TMP_TEST_DIR/cmd.log"'

make_fake_agent_bin "$FAKE_BIN" opencode sleep "$TMP_TEST_DIR/opencode.log"
PATH="$FAKE_BIN:$PATH" "$FAKE_BIN/opencode" run "cleanup probe" &
FAKE_AGENT_PID=$!
sleep 1
OUTPUT=$(./cleanup.sh --dry-run 2>&1)
EXIT_CODE=$?
kill "$FAKE_AGENT_PID" 2>/dev/null || true
wait "$FAKE_AGENT_PID" 2>/dev/null || true
test_it "cleanup: detects fake opencode run process" 'output_contains "Would kill" && output_contains "opencode"'

rm -rf "$TMP_TEST_DIR"

echo ""

# ============================================
# Option parsing
# ============================================
echo "## Option parsing"

# Test: --batch is recognized
OUTPUT=$(./run.sh tests/fixtures/incomplete.json --batch 3 --dry-run 2>&1)
EXIT_CODE=$?
test_it "--batch: sets batch size" 'output_contains "Batch size: 3"'

# Test: --delay is recognized
OUTPUT=$(./run.sh tests/fixtures/incomplete.json --delay 5 --dry-run 2>&1)
EXIT_CODE=$?
test_it "--delay: sets delay" 'output_contains "Delay between sessions: 5s"'

# Test: Multiple options work together
OUTPUT=$(./run.sh tests/fixtures/incomplete.json --batch 2 --delay 10 --dry-run 2>&1)
EXIT_CODE=$?
test_it "multiple options: all parsed" 'output_contains "Batch size: 2" && output_contains "Delay between sessions: 10s"'

echo ""

# ============================================
# Summary
# ============================================
echo "========================================"
if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All $TOTAL tests passed${NC}"
    exit 0
else
    echo -e "${RED}$FAILED of $TOTAL tests failed${NC}"
    exit 1
fi
