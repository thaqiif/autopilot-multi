---
name: cancel
description: Cancel an active autopilotagent loop by removing the state file.
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Command Code
---

## Purpose

Use this skill when the user asks to cancel an autopilotagent loop or stop a running TDD session.

## Source of Truth

Read `commands/cancel.md` before executing. Do not invent a parallel implementation.

## Execution Rules

1. Remove the loop state file (`.autopilotagent/loop-state.md`).
2. Confirm cancellation to the user.
