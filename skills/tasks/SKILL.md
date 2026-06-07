---
name: tasks
description: Convert an approved PRD into a machine-readable JSON task file for autonomous TDD execution.
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Command Code
---

## Purpose

Use this skill when the user asks to convert a PRD to tasks, generate a task file, or prepare a PRD for autonomous execution.

## Source of Truth

Read `commands/tasks.md` before executing. Do not invent a parallel implementation.

## Execution Rules

1. Analyze the codebase to understand existing patterns before generating tasks.
2. Generate a machine-readable JSON task file with TDD tracking fields.
3. Save to `docs/autopilotagent/<feature-name>/<feature-name>.json`.
4. When complete, print `COMPLETE` and exit.
