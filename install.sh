#!/bin/bash

# Autopilotagent Install Script
# Creates symlinks from this repo to supported agent config directories.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Autopilotagent commands..."

# Create directories if they don't exist
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/hooks

# Symlink command files
for cmd in prd.md tasks.md autopilotagent.md autopilotagent:init.md analyze.md; do
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
link_agent_file "$SCRIPT_DIR/commands" ~/.codex/autopilotagent/commands "commands/ → ~/.codex/autopilotagent/commands"
link_agent_file "$SCRIPT_DIR/skills/autopilotagent" ~/.agents/skills/autopilotagent "autopilotagent skill → ~/.agents/skills/autopilotagent"

link_agent_file "$SCRIPT_DIR/AGENTS.md" ~/.config/opencode/AGENTS.md "AGENTS.md → ~/.config/opencode/AGENTS.md"
link_agent_file "$SCRIPT_DIR/commands" ~/.config/opencode/autopilotagent/commands "commands/ → ~/.config/opencode/autopilotagent/commands"
link_agent_file "$SCRIPT_DIR/skills/autopilotagent" ~/.config/opencode/skills/autopilotagent "autopilotagent skill → ~/.config/opencode/skills/autopilotagent"

link_agent_file "$SCRIPT_DIR/AGENTS.md" ~/.commandcode/AGENTS.md "AGENTS.md → ~/.commandcode/AGENTS.md"
link_agent_file "$SCRIPT_DIR/commands" ~/.commandcode/autopilotagent/commands "commands/ → ~/.commandcode/autopilotagent/commands"
link_agent_file "$SCRIPT_DIR/skills/autopilotagent" ~/.commandcode/skills/autopilotagent "autopilotagent skill → ~/.commandcode/skills/autopilotagent"

link_agent_file "$SCRIPT_DIR/skills/autopilotagent" ~/.claude/skills/autopilotagent "autopilotagent skill → ~/.claude/skills/autopilotagent"

# Install stop-hook for loop mechanism
echo ""
echo "Installing loop hooks..."

if [ -L ~/.claude/hooks/autopilotagent-stop-hook.sh ]; then
    rm ~/.claude/hooks/autopilotagent-stop-hook.sh
elif [ -f ~/.claude/hooks/autopilotagent-stop-hook.sh ]; then
    echo "Backing up existing autopilotagent-stop-hook.sh"
    mv ~/.claude/hooks/autopilotagent-stop-hook.sh ~/.claude/hooks/autopilotagent-stop-hook.sh.bak
fi
ln -s "$SCRIPT_DIR/hooks/stop-hook.sh" ~/.claude/hooks/autopilotagent-stop-hook.sh
chmod +x ~/.claude/hooks/autopilotagent-stop-hook.sh
echo "  Linked: stop-hook.sh → ~/.claude/hooks/autopilotagent-stop-hook.sh"

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
    # Check if autopilotagent hook is already configured
    if grep -q "autopilotagent-stop-hook" "$HOOKS_JSON" 2>/dev/null; then
        echo "  Hooks already configured in $HOOKS_JSON"
    else
        echo "  Note: Add autopilotagent stop-hook to your $HOOKS_JSON manually:"
        echo '    "stop": [{"command": "~/.claude/hooks/autopilotagent-stop-hook.sh"}]'
    fi
else
    # Create hooks.json with autopilotagent hook
    cat > "$HOOKS_JSON" << 'HOOKEOF'
{
  "hooks": {
    "stop": [
      {
        "command": "~/.claude/hooks/autopilotagent-stop-hook.sh",
        "description": "Autopilotagent loop mechanism"
      }
    ]
  }
}
HOOKEOF
    echo "  Created: $HOOKS_JSON with autopilotagent stop-hook"
fi

# Symlink run.sh to ~/.local/bin/autopilotagent
mkdir -p ~/.local/bin
if [ -L ~/.local/bin/autopilotagent ]; then
    rm ~/.local/bin/autopilotagent
elif [ -f ~/.local/bin/autopilotagent ]; then
    echo "Backing up existing ~/.local/bin/autopilotagent to autopilotagent.bak"
    mv ~/.local/bin/autopilotagent ~/.local/bin/autopilotagent.bak
fi
ln -s "$SCRIPT_DIR/run.sh" ~/.local/bin/autopilotagent
echo "  Linked: run.sh → ~/.local/bin/autopilotagent"

# Symlink cleanup.sh
if [ -L ~/.local/bin/autopilotagent-cleanup ]; then
    rm ~/.local/bin/autopilotagent-cleanup
elif [ -f ~/.local/bin/autopilotagent-cleanup ]; then
    echo "Backing up existing ~/.local/bin/autopilotagent-cleanup to autopilotagent-cleanup.bak"
    mv ~/.local/bin/autopilotagent-cleanup ~/.local/bin/autopilotagent-cleanup.bak
fi
ln -s "$SCRIPT_DIR/cleanup.sh" ~/.local/bin/autopilotagent-cleanup
echo "  Linked: cleanup.sh → ~/.local/bin/autopilotagent-cleanup"

echo ""
echo "Installation complete!"
echo ""
echo "Commands available:"
echo "  /prd               - Create a PRD (inside Claude)"
echo "  /tasks             - Convert PRD to tasks (inside Claude)"
echo "  /autopilotagent         - Run TDD execution (inside Claude)"
echo "  /autopilotagent init    - Initialize project configuration (inside Claude)"
echo "  /autopilotagent stop    - Stop run.sh wrapper gracefully (inside Claude)"
echo "  /autopilotagent cancel  - Cancel hook-based loop (inside Claude)"
echo "  /autopilotagent analyze - Analyze session analytics (inside Claude)"
echo ""
echo "  autopilotagent       - Token-frugal wrapper (from terminal)"
echo "  autopilotagent-cleanup - Kill orphaned Claude processes (from terminal)"
echo ""
echo "Agents supported: claude, codex, opencode, cmd"
echo ""
echo "Usage:"
echo "  autopilotagent docs/autopilotagent/feature/feature.json    # Fresh context per requirement"
echo "  autopilotagent tasks.json --batch 3            # 3 requirements per session"
echo "  autopilotagent tasks.json --agent codex        # Use Codex CLI"
echo "  autopilotagent tasks.json --agent opencode     # Use OpenCode CLI"
echo "  autopilotagent tasks.json --agent cmd          # Use Command Code CLI"
echo ""
echo "Run '/autopilotagent init' in your project to set up configuration."
echo ""
echo "Note: Ensure ~/.local/bin is in your PATH. Add to ~/.bashrc or ~/.zshrc:"
echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
