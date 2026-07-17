---
name: cancel
description: Cancel an active autopilotagent loop by removing the state file.
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Command Code
---

## Purpose

Use this skill when the user asks to cancel an autopilotagent loop or stop a running TDD session.

## Source of Truth

Read the full command spec before executing. The spec is at one of these locations depending on your agent:
- Claude Code: `~/.claude/commands/cancel.md`
- Command Code: `~/.commandcode/autopilotagent/commands/cancel.md`
- OpenCode: `~/.config/opencode/autopilotagent/commands/cancel.md`
- Codex: `~/.codex/autopilotagent/commands/cancel.md`

Do not invent a parallel implementation.

## Execution Rules

1. Remove the loop state file (`.autopilotagent/loop-state.md`).
2. Confirm cancellation to the user.
