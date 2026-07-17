---
name: autopilotagent
description: Run Autopilotagent autonomous TDD workflows from PRDs and task JSON files, including fresh-session loops, task progress tracking, notes, analytics, and guarded commits.
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Command Code
---

## Purpose

Use this skill when the user asks to run or continue Autopilotagent, convert PRDs into task JSON, initialize Autopilotagent configuration, or execute autonomous TDD requirements from a task file.

## Source of Truth

Autopilotagent command behavior lives in the repository command specs. Resolve paths based on your agent:

- Claude Code: `~/.claude/commands/*.md` and `~/.claude/AGENTS.md`
- Command Code: `~/.commandcode/autopilotagent/commands/*.md` and `~/.commandcode/AGENTS.md`
- OpenCode: `~/.config/opencode/autopilotagent/commands/*.md` and `~/.config/opencode/AGENTS.md`
- Codex: `~/.codex/autopilotagent/commands/*.md` and `~/.codex/AGENTS.md`

Read the relevant command spec before executing a workflow. Do not invent a parallel implementation.

## Execution Rules

1. Follow `AGENTS.md` guardrails: test before implementation, search before creating code, no placeholders, and no commits with failing feedback loops.
2. For task JSON runs, process one workable requirement at a time unless the prompt specifies a batch size.
3. Update the task JSON, notes file, git tags, commits, and analytics exactly as the `autopilotagent.md` command spec describes.
4. If running headlessly, do not rely on slash-command registration. Treat `/autopilotagent ...`, `/tasks ...`, `/prd ...`, and `/analyze ...` as instructions to execute the corresponding command spec.
5. When the requested batch or command is complete, print `COMPLETE` and exit.

## Loop Contract

The outer `autopilotagent` shell wrapper decides whether to launch another fresh session by reading the task JSON. Mark requirements with `passes: true`, `stuck: true`, or `invalidTest: true` so the wrapper can progress or stop correctly.
