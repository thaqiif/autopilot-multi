# Cancel Autopilotagent Loop

Stop an active autopilotagent loop by removing the state file.

## Usage

```
/autopilotagent cancel
```

## How It Works

The autopilotagent loop uses a state file (`.autopilotagent/loop-state.md`) to track iteration progress. When the stop-hook intercepts an exit attempt, it checks for this file to determine if looping should continue.

Canceling the loop simply removes this state file. Without it, the stop-hook will allow Claude to exit normally on the next iteration.

## Execution

1. Check if the state file exists:

```bash
test -f .autopilotagent/loop-state.md && echo "EXISTS" || echo "NOT_FOUND"
```

2. **If no state file exists:**

Tell the user:
```
No active autopilotagent loop found.

If you're trying to stop the run.sh wrapper, use:
  /autopilotagent stop
Or press Ctrl+C in the terminal running the wrapper.
```

3. **If state file exists:**

Read the current iteration from the file, then delete it:

```bash
rm .autopilotagent/loop-state.md
```

Tell the user:
```
Autopilotagent loop canceled at iteration N.

The loop will exit on the next iteration attempt.
Note: Any work in progress will complete before the loop stops.
```

## Notes

- This cancels the **hook-based loop** (single session with context accumulation)
- For the **bash wrapper** (`run.sh`), use `/autopilotagent stop` instead
- Canceling is graceful - current work completes before stopping
- If you need to stop immediately, use Ctrl+C in the terminal
