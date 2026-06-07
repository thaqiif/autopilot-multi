# Stop Autopilotagent

Gracefully stop the autopilotagent run.sh loop after the current session completes.

## Usage

```
/autopilotagent stop
```

## How It Works

This command creates a `.autopilotagent-stop` sentinel file in the current directory. The `run.sh` script checks for this file between sessions and exits gracefully when found.

## Execution

Create the stop file to signal run.sh to stop:

```bash
touch .autopilotagent-stop
```

Then confirm to the user:

```
Autopilotagent stop signal sent. The run.sh loop will exit after the current session completes.

If you need to stop immediately, press Ctrl+C in the terminal running run.sh.
```
