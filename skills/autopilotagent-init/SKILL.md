---
name: autopilotagent-init
description: Initialize a project for autopilotagent by detecting configuration and creating autopilotagent.json.
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Command Code
---

## Purpose

Use this skill when the user asks to initialize autopilotagent, set up project configuration, or create autopilotagent.json.

## Source of Truth

Read the full command spec before executing. The spec is at one of these locations depending on your agent:
- Claude Code: `~/.claude/commands/autopilotagent:init.md`
- Command Code: `~/.commandcode/autopilotagent/commands/autopilotagent:init.md`
- OpenCode: `~/.config/opencode/autopilotagent/commands/autopilotagent:init.md`
- Codex: `~/.codex/autopilotagent/commands/autopilotagent:init.md`

Do not invent a parallel implementation.

## Execution Rules

1. Run pre-flight checks to verify the environment is ready.
2. Detect project type, test command, lint command, and conventions.
3. Create `autopilotagent.json` in the project root.
4. When complete, print `COMPLETE` and exit.
