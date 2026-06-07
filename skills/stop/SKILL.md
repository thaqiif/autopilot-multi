---
name: stop
description: Gracefully stop the autopilotagent run.sh loop after the current session completes.
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Command Code
---

## Purpose

Use this skill when the user asks to gracefully stop the autopilotagent wrapper loop.

## Source of Truth

Read the full command spec before executing. The spec is at one of these locations depending on your agent:
- Claude Code: `~/.claude/commands/stop.md`
- Command Code: `~/.commandcode/autopilotagent/commands/stop.md`
- OpenCode: `~/.config/opencode/autopilotagent/commands/stop.md`
- Codex: `~/.codex/autopilotagent/commands/stop.md`

Do not invent a parallel implementation.

## Execution Rules

1. Signal the run.sh wrapper to exit after the current session.
2. Confirm to the user that the loop will stop after this iteration.
