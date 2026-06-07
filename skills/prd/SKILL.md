---
name: prd
description: Create a Product Requirements Document (PRD) by asking clarifying questions and generating a structured markdown spec.
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Command Code
---

## Purpose

Use this skill when the user asks to create a PRD, write requirements, or spec out a new feature.

## Source of Truth

Read the full command spec before executing. The spec is at one of these locations depending on your agent:
- Claude Code: `~/.claude/commands/prd.md`
- Command Code: `~/.commandcode/autopilotagent/commands/prd.md`
- OpenCode: `~/.config/opencode/autopilotagent/commands/prd.md`
- Codex: `~/.codex/autopilotagent/commands/prd.md`

Do not invent a parallel implementation.

## Execution Rules

1. Ask clarifying questions one at a time to understand the feature fully.
2. Generate a structured PRD in markdown format.
3. Save to `docs/autopilotagent/<feature-name>/<feature-name>.md`.
4. When complete, print `COMPLETE` and exit.
