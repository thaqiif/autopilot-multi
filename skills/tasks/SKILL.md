---
name: tasks
description: Convert an approved PRD into a machine-readable JSON task file for autonomous TDD execution.
license: MIT
compatibility: Claude Code, Codex CLI, OpenCode, Command Code
---

## Purpose

Use this skill when the user asks to convert a PRD to tasks, generate a task file, or prepare a PRD for autonomous execution.

## Source of Truth

Read the full command spec before executing. The spec is at one of these locations depending on your agent:
- Claude Code: `~/.claude/commands/tasks.md`
- Command Code: `~/.commandcode/autopilotagent/commands/tasks.md`
- OpenCode: `~/.config/opencode/autopilotagent/commands/tasks.md`
- Codex: `~/.codex/autopilotagent/commands/tasks.md`

If none are accessible, use the schema below. Do not invent a parallel implementation.

## CRITICAL: Exact JSON Schema

The output MUST use these EXACT key names. The autopilotagent runner will reject files that deviate.

```json
{
  "name": "feature-name",
  "description": "Brief description from PRD",
  "goals": ["Goal 1"],
  "nonGoals": ["What this will NOT do"],
  "technicalNotes": "Constraints or dependencies",
  "_tdd": true,
  "requirements": [
    {
      "id": "1",
      "category": "functional",
      "description": "Clear description of this requirement",
      "codeAnalysis": {
        "approach": "create|extend|modify|already-done",
        "existingFiles": [],
        "relatedTests": [],
        "patterns": [],
        "targetFiles": { "modify": [], "create": [] }
      },
      "acceptance": [
        "Specific testable outcome 1",
        "Specific testable outcome 2"
      ],
      "tdd": {
        "test": { "description": "...", "file": "path/to/test.ts", "passes": false },
        "implement": { "description": "...", "passes": false },
        "refactor": { "description": "...", "passes": false }
      },
      "verification": ["Step 1", "Step 2"],
      "passes": false
    }
  ]
}
```

### Key Name Rules (DO NOT deviate)

| You MUST use | Do NOT use |
|-------------|-----------|
| `requirements` | tasks, items, stories |
| `description` | title, name, summary |
| `acceptance` | acceptanceCriteria, criteria, conditions |
| `tdd.test` with `description`, `file`, `passes` | testFile, testStatus |
| `tdd.implement` with `description`, `passes` | implementationStatus |
| `tdd.refactor` with `description`, `passes` | (often missing entirely) |
| `category` | type, kind |
| `verification` | checks, verify |
| `passes` (boolean, false) | status, done |

## Execution Rules

1. Analyze the codebase to understand existing patterns before generating tasks.
2. Generate a JSON task file matching the EXACT schema above.
3. Validate: top-level key is `requirements` (not `tasks`), every item has `tdd` with `test`/`implement`/`refactor`.
4. Save to `docs/autopilotagent/<feature-name>/<feature-name>.json`.
5. When complete, print `COMPLETE` and exit.
