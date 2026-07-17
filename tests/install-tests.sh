#!/bin/bash
#
# install-tests.sh - Test install.sh output without touching the real home dir.

cd "$(dirname "$0")/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASSED=0
FAILED=0
TOTAL=0

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

strip_colors() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

output_contains() {
    local clean_output
    clean_output=$(strip_colors "$OUTPUT")
    [[ "$clean_output" == *"$1"* ]]
}

TMP_HOME=$(mktemp -d)
trap 'rm -rf "$TMP_HOME"' EXIT

echo "Running install.sh tests..."
echo ""

OUTPUT=$(HOME="$TMP_HOME" ./install.sh 2>&1)
EXIT_CODE=$?

test_it "install exits successfully" '[[ "$EXIT_CODE" == "0" ]]'
test_it "installs claude command files" '[[ -L "$TMP_HOME/.claude/commands/autopilotagent.md" ]]'
test_it "installs codex instructions" '[[ -L "$TMP_HOME/.codex/AGENTS.md" ]]'
test_it "installs opencode instructions" '[[ -L "$TMP_HOME/.config/opencode/AGENTS.md" ]]'
test_it "installs command code instructions" '[[ -L "$TMP_HOME/.commandcode/AGENTS.md" ]]'
test_it "installs shared agent skill" '[[ -L "$TMP_HOME/.agents/skills/autopilotagent" ]]'
test_it "installs claude skill" '[[ -L "$TMP_HOME/.claude/skills/autopilotagent" ]]'
test_it "installs opencode skill" '[[ -L "$TMP_HOME/.config/opencode/skills/autopilotagent" ]]'
test_it "installs command code skill" '[[ -L "$TMP_HOME/.commandcode/skills/autopilotagent" ]]'
test_it "advertises multi-agent runner" 'output_contains "Agents supported: claude, codex, opencode, cmd"'

echo ""
echo "========================================"
if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}All $TOTAL install tests passed${NC}"
    exit 0
else
    echo -e "${RED}$FAILED of $TOTAL install tests failed${NC}"
    exit 1
fi
