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

#############################################
# Detect Laravel + Laravel Sail environment #
#############################################

## Detect Laravel projects strictly and bail out when not detected
# Consider it Laravel only when the repo has the canonical `artisan` entrypoint
# or a composer.json that depends on `laravel/framework`.
is_laravel=false
if [ -f "artisan" ] || ( [ -f "composer.json" ] && grep -q '"laravel/framework"' composer.json ); then
  is_laravel=true
fi

# If not a Laravel project, exit quietly so the plugin does NOT activate
if [ "$is_laravel" != true ]; then
  exit 0
fi

## Detect Sail availability by executable presence, not composer.json
# Treat Sail as available when either vendor/bin/sail exists/executable, or a top-level
# ./sail helper script is present. We intentionally avoid parsing composer.json.
sail_available=false
if [ -x ./vendor/bin/sail ] || [ -f ./sail ]; then
  sail_available=true
fi

# Detect if Sail (docker compose) containers are running for this project
containers_running=false
compose_cmd=""
if command -v docker >/dev/null 2>&1; then
  # Prefer `docker compose` plugin
  if docker compose version >/dev/null 2>&1; then
    compose_cmd="docker compose"
  fi
fi
if [ -z "$compose_cmd" ] && command -v docker-compose >/dev/null 2>&1; then
  compose_cmd="docker-compose"
fi

if [ -n "$compose_cmd" ]; then
  # Run quietly; if any service container exists and is running, consider Sail "up"
  if $compose_cmd ps -q >/dev/null 2>&1; then
    if [ -n "$($compose_cmd ps -q 2>/dev/null)" ]; then
      containers_running=true
    fi
  fi
fi

# Test override to simulate container status in CI
if [ "${SUPERPOWERS_TEST_SAIL_RUNNING:-}" = "true" ]; then
  containers_running=true
elif [ "${SUPERPOWERS_TEST_SAIL_RUNNING:-}" = "false" ]; then
  containers_running=false
fi

# Read Laravel intro skill
laravel_intro_content=""
if [ -f "${PLUGIN_ROOT}/skills/using-laravel-superpowers/SKILL.md" ]; then
  laravel_intro_content=$(cat "${PLUGIN_ROOT}/skills/using-laravel-superpowers/SKILL.md" 2>&1 || echo "")
fi

# Escape outputs for JSON
laravel_intro_escaped=$(echo "$laravel_intro_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
warning_escaped=$(echo "$warning_message" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Build Sail guidance based on detection
sail_guidance=""
if [ "$sail_available" = true ]; then
  sail_guidance="Laravel Sail detected (vendor/bin/sail or ./sail present). Prefer Sail commands inside containers to avoid host/env drift.\n\nKey mappings (Sail | Non‑Sail):\n- sail artisan … | php artisan …\n- sail composer … | composer …\n- sail php … | php …\n- sail pnpm … | pnpm … (or npm/yarn/bun)\n- sail mysql/psql/redis … | mysql/psql/redis-cli …\n\nPortable alias:\n  alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'\n"

  if [ "$containers_running" = false ]; then
    sail_guidance+="\nInteractive safety: Sail is present but containers are not running. Before executing any host commands (php, composer, mysql, node, pnpm, npm, yarn), ask the user: \"Start Sail containers now with: 'sail up -d'? Or proceed using host tools?\" Do not run host commands unless the user explicitly opts to proceed without Sail.\nTip: Start containers: 'sail up -d' then verify: 'sail ps'.\n"
  else
    sail_guidance+="\nSail appears to be running (docker compose ps shows active containers). Use Sail commands (artisan/composer/node/db) and avoid host binaries to keep environments consistent.\n"
  fi
fi

# Escape Sail guidance
sail_guidance_escaped=$(echo "$sail_guidance" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nThis repository appears to be a Laravel project. Read the following onboarding first, then use the 'Skill' tool to run any Laravel skills you need.\n\n${laravel_intro_escaped}\n\n${sail_guidance_escaped}\n\n${warning_escaped}\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
