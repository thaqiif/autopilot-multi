---
name: analyze
description: Analyze autopilotagent session analytics to identify waste patterns and generate improvement suggestions.
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Command Code
---

## Purpose

Use this skill when the user asks to analyze session analytics, review autopilotagent performance, or get improvement suggestions.

## Source of Truth

Read `commands/analyze.md` before executing. Do not invent a parallel implementation.

## Execution Rules

1. Scan `docs/autopilotagent/*/analytics/` for session analytics files.
2. Identify waste patterns: thrashing, environment issues, missing context, invalid tests.
3. Generate actionable improvement suggestions.
4. When complete, print `COMPLETE` and exit.
