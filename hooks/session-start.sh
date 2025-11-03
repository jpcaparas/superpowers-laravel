#!/usr/bin/env bash
# SessionStart hook for superpowers plugin

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Check if legacy skills directory exists and build warning
warning_message=""
legacy_skills_dir="${HOME}/.config/superpowers/skills"
if [ -d "$legacy_skills_dir" ]; then
    warning_message="\n\n<important-reminder>IN YOUR FIRST REPLY AFTER SEEING THIS MESSAGE YOU MUST TELL THE USER:⚠️ **WARNING:** Superpowers now uses Claude Code's skills system. Custom skills in ~/.config/superpowers/skills will not be read. Move custom skills to ~/.claude/skills instead. To make this message go away, remove ~/.config/superpowers/skills</important-reminder>"
fi

### Laravel-centric startup: optionally inject Laravel intro only

# Detect Laravel projects (artisan file or laravel/framework in composer.json)
is_laravel=false
if [ -f "artisan" ] || ( [ -f "composer.json" ] && grep -q '"laravel/framework"' composer.json ); then
  is_laravel=true
fi

# Read Laravel intro skill if applicable
laravel_intro_content=""
if [ "$is_laravel" = true ] && [ -f "${PLUGIN_ROOT}/skills/using-laravel-superpowers/SKILL.md" ]; then
  laravel_intro_content=$(cat "${PLUGIN_ROOT}/skills/using-laravel-superpowers/SKILL.md" 2>&1 || echo "")
fi

# Escape outputs for JSON
laravel_intro_escaped=$(echo "$laravel_intro_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
warning_escaped=$(echo "$warning_message" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nThis repository appears to be a Laravel project. Read the following onboarding first, then use the 'Skill' tool to run any Laravel skills you need.\n\n${laravel_intro_escaped}\n\n${warning_escaped}\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
