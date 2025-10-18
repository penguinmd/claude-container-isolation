#!/usr/bin/env bash
# SessionStart hook for container-isolation plugin

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# GitHub repository URL
REPO_URL="https://github.com/penguinmd/claude-container-isolation.git"

# Update function
update_plugin() {
    local update_status=""

    # Check if this is a git repository
    if [ -d "${PLUGIN_ROOT}/.git" ]; then
        cd "${PLUGIN_ROOT}"

        # Fetch from origin
        if git fetch origin 2>/dev/null; then
            # Get commit references
            LOCAL=$(git rev-parse @ 2>/dev/null || echo "")
            REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
            BASE=$(git merge-base @ @{u} 2>/dev/null || echo "")

            # Check if update is possible
            if [ -n "$LOCAL" ] && [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
                # Check if we can fast-forward (local is ancestor of remote)
                if [ "$LOCAL" = "$BASE" ]; then
                    # Fast-forward merge is possible
                    if git merge --ff-only @{u} 2>&1 >/dev/null; then
                        update_status="✓ Container-isolation plugin updated to latest version"
                    else
                        update_status="⚠️ Container-isolation plugin update available but couldn't auto-merge"
                    fi
                elif [ "$REMOTE" != "$BASE" ]; then
                    # Remote has changes (local is behind or diverged)
                    update_status="⚠️ Container-isolation plugin has updates available (local modifications present)"
                fi
            fi
        fi
    fi

    echo "$update_status"
}

# Run update check
update_message=$(update_plugin)

# Read the skill metadata
skill_name="Container Isolation for Claude Code"
skill_description="Create secure, isolated development environments using Apple Container for running Claude Code safely"
when_to_use="when you need to test untrusted or AI-generated code safely, experiment with new libraries without risking your system, or create reproducible development environments"

# Build update message if present
update_display=""
if [ -n "$update_message" ]; then
    update_display="${update_message}\n\n"
fi

# Escape for JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}'
}

update_escaped=$(escape_json "$update_display")
skill_name_escaped=$(escape_json "$skill_name")
skill_description_escaped=$(escape_json "$skill_description")
when_to_use_escaped=$(escape_json "$when_to_use")

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${update_escaped}**Container Isolation Skill Available**\n\nSkill: ${skill_name_escaped}\nDescription: ${skill_description_escaped}\nWhen to use: ${when_to_use_escaped}\n\n**Slash command:** /container - Manage isolated container environments (setup, status, shell, stop)\n\n**Skill location:** ${PLUGIN_ROOT}/SKILL.md"
  }
}
EOF

exit 0
