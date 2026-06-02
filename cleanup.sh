#!/bin/bash
#
# cleanup.sh - Kill orphaned agent processes
#
# Agent CLIs can leave behind orphaned MCP servers, subagent processes,
# and worker threads that consume memory indefinitely. This script finds
# and kills them.
#
# Usage:
#   ./cleanup.sh           # Kill background orphans only (safe)
#   ./cleanup.sh --all     # Kill ALL Claude-related processes
#   ./cleanup.sh --dry-run # Show what would be killed without killing
#   ./cleanup.sh --help    # Show help
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MODE="background"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            MODE="all"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "cleanup.sh - Kill orphaned agent processes"
            echo ""
            echo "Usage:"
            echo "  ./cleanup.sh           Kill background/orphaned processes only (safe)"
            echo "  ./cleanup.sh --all     Kill ALL agent-related processes"
            echo "  ./cleanup.sh --dry-run Show what would be killed"
            echo ""
            echo "By default, only kills processes with no controlling terminal (orphans)."
            echo "Use --all to also kill processes attached to terminals."
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Run with --help for usage"
            exit 1
            ;;
    esac
done

is_supported_agent_process() {
    local cmdline="$1"
    local previous_base=""
    local token base

    [[ "$cmdline" == *"claude-mem"*mcp-server* ]] && return 0
    [[ "$cmdline" == *"chroma-mcp"* ]] && return 0
    [[ "$cmdline" == *"worker-service"* ]] && return 0

    for token in $cmdline; do
        base=$(basename -- "$token")
        case "$base" in
            claude)
                return 0
                ;;
            exec)
                [[ "$previous_base" == "codex" ]] && return 0
                ;;
            run)
                [[ "$previous_base" == "opencode" ]] && return 0
                ;;
            -p|--print)
                [[ "$previous_base" == "cmd" ]] && return 0
                ;;
        esac
        previous_base="$base"
    done

    return 1
}

FOUND=0
PIDS=""

echo -e "${BLUE}Scanning for agent-related processes...${NC}"
if [[ "$MODE" == "background" ]]; then
    echo -e "${BLUE}Mode: background only (orphans without controlling terminal)${NC}"
else
    echo -e "${YELLOW}Mode: ALL agent-related processes${NC}"
fi
echo ""

while read -r pid tty rss age cmd; do
    [[ -z "$pid" ]] && continue

    # Skip our own script
    [[ "$pid" == "$$" ]] && continue
    is_supported_agent_process "$cmd" || continue

    # In background mode, skip processes with a controlling terminal
    if [[ "$MODE" == "background" && "$tty" != "?" ]]; then
        continue
    fi

    # Convert RSS (KB) to MB for display
    mem_mb=$((rss / 1024))

    FOUND=$((FOUND + 1))
    PIDS="$PIDS $pid"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}Would kill${NC} PID $pid (${mem_mb}MB, tty=$tty, age=${age}s)"
        echo -e "    ${cmd:0:100}"
    else
        echo -e "  ${RED}Killing${NC} PID $pid (${mem_mb}MB, tty=$tty, age=${age}s)"
        echo -e "    ${cmd:0:100}"
        kill -TERM "$pid" 2>/dev/null || true
    fi
done < <(ps -eo pid=,tty=,rss=,etimes=,args= 2>/dev/null || true)

echo ""

if [[ $FOUND -eq 0 ]]; then
    echo -e "${GREEN}No agent-related processes found${NC}"
    exit 0
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}$FOUND process(es) would be killed${NC}"
    echo "Run without --dry-run to kill them."
    exit 0
fi

# Wait for graceful shutdown, then force kill survivors
echo -e "${BLUE}Waiting for graceful shutdown...${NC}"
sleep 3

SURVIVORS=0
for pid in $PIDS; do
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "  ${RED}Force killing${NC} PID $pid (did not respond to SIGTERM)"
        kill -KILL "$pid" 2>/dev/null || true
        SURVIVORS=$((SURVIVORS + 1))
    fi
done

echo ""
echo -e "${GREEN}Cleaned up $FOUND process(es)${NC}"
if [[ $SURVIVORS -gt 0 ]]; then
    echo -e "${YELLOW}$SURVIVORS required SIGKILL (force kill)${NC}"
fi
