#!/bin/bash

# Autopilot Install Script
# Creates symlinks from this repo to supported agent config directories.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Autopilot commands..."

# Create directories if they don't exist
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/hooks

# Symlink command files
for cmd in prd.md tasks.md autopilot.md autopilot:init.md analyze.md; do
    if [ -L ~/.claude/commands/$cmd ]; then
        rm ~/.claude/commands/$cmd
    elif [ -f ~/.claude/commands/$cmd ]; then
        echo "Backing up existing $cmd to $cmd.bak"
        mv ~/.claude/commands/$cmd ~/.claude/commands/$cmd.bak
    fi
    ln -s "$SCRIPT_DIR/commands/$cmd" ~/.claude/commands/$cmd
    echo "  Linked: $cmd"
done

# Symlink AGENTS.md
if [ -L ~/.claude/AGENTS.md ]; then
    rm ~/.claude/AGENTS.md
elif [ -f ~/.claude/AGENTS.md ]; then
    echo "Backing up existing AGENTS.md to AGENTS.md.bak"
    mv ~/.claude/AGENTS.md ~/.claude/AGENTS.md.bak
fi
ln -s "$SCRIPT_DIR/AGENTS.md" ~/.claude/AGENTS.md
echo "  Linked: AGENTS.md"

# Install shared instructions/specs and skills for non-Claude agents. These
# agents do not consume Claude slash-command files directly, but run.sh points
# them at these specs during headless execution.
echo ""
echo "Installing shared instructions for Codex, OpenCode, and Command Code..."

link_agent_file() {
    local source="$1"
    local target="$2"
    local label="$3"

    mkdir -p "$(dirname "$target")"
    if [ -L "$target" ]; then
        rm "$target"
    elif [ -f "$target" ] || [ -d "$target" ]; then
        echo "Backing up existing $target to $target.bak"
        mv "$target" "$target.bak"
    fi
    ln -s "$source" "$target"
    echo "  Linked: $label"
}

link_agent_file "$SCRIPT_DIR/AGENTS.md" ~/.codex/AGENTS.md "AGENTS.md → ~/.codex/AGENTS.md"
link_agent_file "$SCRIPT_DIR/commands" ~/.codex/autopilot/commands "commands/ → ~/.codex/autopilot/commands"
link_agent_file "$SCRIPT_DIR/skills/autopilot" ~/.agents/skills/autopilot "autopilot skill → ~/.agents/skills/autopilot"

link_agent_file "$SCRIPT_DIR/AGENTS.md" ~/.config/opencode/AGENTS.md "AGENTS.md → ~/.config/opencode/AGENTS.md"
link_agent_file "$SCRIPT_DIR/commands" ~/.config/opencode/autopilot/commands "commands/ → ~/.config/opencode/autopilot/commands"
link_agent_file "$SCRIPT_DIR/skills/autopilot" ~/.config/opencode/skills/autopilot "autopilot skill → ~/.config/opencode/skills/autopilot"

link_agent_file "$SCRIPT_DIR/AGENTS.md" ~/.commandcode/AGENTS.md "AGENTS.md → ~/.commandcode/AGENTS.md"
link_agent_file "$SCRIPT_DIR/commands" ~/.commandcode/autopilot/commands "commands/ → ~/.commandcode/autopilot/commands"
link_agent_file "$SCRIPT_DIR/skills/autopilot" ~/.commandcode/skills/autopilot "autopilot skill → ~/.commandcode/skills/autopilot"

link_agent_file "$SCRIPT_DIR/skills/autopilot" ~/.claude/skills/autopilot "autopilot skill → ~/.claude/skills/autopilot"

# Install stop-hook for loop mechanism
echo ""
echo "Installing loop hooks..."

if [ -L ~/.claude/hooks/autopilot-stop-hook.sh ]; then
    rm ~/.claude/hooks/autopilot-stop-hook.sh
elif [ -f ~/.claude/hooks/autopilot-stop-hook.sh ]; then
    echo "Backing up existing autopilot-stop-hook.sh"
    mv ~/.claude/hooks/autopilot-stop-hook.sh ~/.claude/hooks/autopilot-stop-hook.sh.bak
fi
ln -s "$SCRIPT_DIR/hooks/stop-hook.sh" ~/.claude/hooks/autopilot-stop-hook.sh
chmod +x ~/.claude/hooks/autopilot-stop-hook.sh
echo "  Linked: stop-hook.sh → ~/.claude/hooks/autopilot-stop-hook.sh"

# Symlink git-commit mutex for parallel agent support
if [ -L ~/.claude/hooks/git-commit ]; then
    rm ~/.claude/hooks/git-commit
elif [ -f ~/.claude/hooks/git-commit ]; then
    echo "Backing up existing git-commit to git-commit.bak"
    mv ~/.claude/hooks/git-commit ~/.claude/hooks/git-commit.bak
fi
ln -s "$SCRIPT_DIR/hooks/git-commit" ~/.claude/hooks/git-commit
chmod +x ~/.claude/hooks/git-commit
echo "  Linked: git-commit → ~/.claude/hooks/git-commit"

# Check if hooks.json exists and update it
HOOKS_JSON=~/.claude/hooks.json
if [ -f "$HOOKS_JSON" ]; then
    # Check if autopilot hook is already configured
    if grep -q "autopilot-stop-hook" "$HOOKS_JSON" 2>/dev/null; then
        echo "  Hooks already configured in $HOOKS_JSON"
    else
        echo "  Note: Add autopilot stop-hook to your $HOOKS_JSON manually:"
        echo '    "stop": [{"command": "~/.claude/hooks/autopilot-stop-hook.sh"}]'
    fi
else
    # Create hooks.json with autopilot hook
    cat > "$HOOKS_JSON" << 'HOOKEOF'
{
  "hooks": {
    "stop": [
      {
        "command": "~/.claude/hooks/autopilot-stop-hook.sh",
        "description": "Autopilot loop mechanism"
      }
    ]
  }
}
HOOKEOF
    echo "  Created: $HOOKS_JSON with autopilot stop-hook"
fi

# Symlink run.sh to ~/.local/bin/autopilot
mkdir -p ~/.local/bin
if [ -L ~/.local/bin/autopilot ]; then
    rm ~/.local/bin/autopilot
elif [ -f ~/.local/bin/autopilot ]; then
    echo "Backing up existing ~/.local/bin/autopilot to autopilot.bak"
    mv ~/.local/bin/autopilot ~/.local/bin/autopilot.bak
fi
ln -s "$SCRIPT_DIR/run.sh" ~/.local/bin/autopilot
echo "  Linked: run.sh → ~/.local/bin/autopilot"

# Symlink cleanup.sh
if [ -L ~/.local/bin/autopilot-cleanup ]; then
    rm ~/.local/bin/autopilot-cleanup
elif [ -f ~/.local/bin/autopilot-cleanup ]; then
    echo "Backing up existing ~/.local/bin/autopilot-cleanup to autopilot-cleanup.bak"
    mv ~/.local/bin/autopilot-cleanup ~/.local/bin/autopilot-cleanup.bak
fi
ln -s "$SCRIPT_DIR/cleanup.sh" ~/.local/bin/autopilot-cleanup
echo "  Linked: cleanup.sh → ~/.local/bin/autopilot-cleanup"

echo ""
echo "Installation complete!"
echo ""
echo "Commands available:"
echo "  /prd               - Create a PRD (inside Claude)"
echo "  /tasks             - Convert PRD to tasks (inside Claude)"
echo "  /autopilot         - Run TDD execution (inside Claude)"
echo "  /autopilot init    - Initialize project configuration (inside Claude)"
echo "  /autopilot stop    - Stop run.sh wrapper gracefully (inside Claude)"
echo "  /autopilot cancel  - Cancel hook-based loop (inside Claude)"
echo "  /autopilot analyze - Analyze session analytics (inside Claude)"
echo ""
echo "  autopilot       - Token-frugal wrapper (from terminal)"
echo "  autopilot-cleanup - Kill orphaned Claude processes (from terminal)"
echo ""
echo "Agents supported: claude, codex, opencode, cmd"
echo ""
echo "Usage:"
echo "  autopilot docs/autopilot/feature/feature.json    # Fresh context per requirement"
echo "  autopilot tasks.json --batch 3            # 3 requirements per session"
echo "  autopilot tasks.json --agent codex        # Use Codex CLI"
echo "  autopilot tasks.json --agent opencode     # Use OpenCode CLI"
echo "  autopilot tasks.json --agent cmd          # Use Command Code CLI"
echo ""
echo "Run '/autopilot init' in your project to set up configuration."
echo ""
echo "Note: Ensure ~/.local/bin is in your PATH. Add to ~/.bashrc or ~/.zshrc:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
