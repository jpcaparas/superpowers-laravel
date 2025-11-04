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
# Detect Laravel apps (monorepo-aware)      #
#############################################

# Exclusions to keep scanning fast
EXCLUDES=(
  -path '*/.git*' -o -path '*/node_modules*' -o -path '*/vendor*' -o -path '*/storage*' -o -path '*/.idea*' -o -path '*/.vscode*'
)

find_laravel_apps() {
  # Find artisan files anywhere in the repo (monorepo support)
  if find . -maxdepth 0 >/dev/null 2>&1; then
    # shellcheck disable=SC2068
    find . -type f -name artisan \( ${EXCLUDES[@]} \) -prune -o -type f -name artisan -print 2>/dev/null | sed 's#^\./##'
  else
    # Fallback without -maxdepth (may be slower)
    # shellcheck disable=SC2068
    find . \( ${EXCLUDES[@]} \) -prune -o -type f -name artisan -print 2>/dev/null | sed 's#^\./##'
  fi
}

get_laravel_version_for_dir() {
  local dir="$1"; local version=""; local constraint="";
  if [ -f "$dir/composer.lock" ]; then
    if command -v jq >/dev/null 2>&1; then
      version=$(jq -r '.packages[]? | select(.name=="laravel/framework") | .version' "$dir/composer.lock" 2>/dev/null | head -n1 || true)
    fi
    if [ -z "$version" ]; then
      version=$(awk '/"name"\s*:\s*"laravel\/framework"/{f=1} f && /"version"\s*:/ {gsub(/.*"version"\s*:\s*"/,"",$0); gsub(/".*/ ,"", $0); print; exit}' "$dir/composer.lock" 2>/dev/null || true)
    fi
  fi
  if [ -z "$version" ] && [ -f "$dir/composer.json" ]; then
    if command -v jq >/dev/null 2>&1; then
      constraint=$(jq -r '.require["laravel/framework"] // empty' "$dir/composer.json" 2>/dev/null || true)
    fi
    if [ -z "$constraint" ]; then
      constraint=$(awk '/"laravel\/framework"\s*:\s*"/{gsub(/.*"laravel\/framework"\s*:\s*"/,"",$0); gsub(/".*/ ,"", $0); print; exit}' "$dir/composer.json" 2>/dev/null || true)
    fi
  fi
  if [ -n "$version" ]; then
    echo "$version"
  elif [ -n "$constraint" ]; then
    echo "$constraint"
  else
    echo "unknown"
  fi
}

has_sail_for_dir() {
  local dir="$1";
  if [ -x "$dir/vendor/bin/sail" ] || [ -f "$dir/sail" ]; then
    echo "yes"
  else
    echo "no"
  fi
}

containers_running_for_dir() {
  local dir="$1"; local compose_cmd=""; local running="no";
  if [ "${SUPERPOWERS_TEST_SAIL_RUNNING:-}" = "true" ]; then
    echo "yes"; return 0
  elif [ "${SUPERPOWERS_TEST_SAIL_RUNNING:-}" = "false" ]; then
    echo "no"; return 0
  fi
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    compose_cmd="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    compose_cmd="docker-compose"
  fi
  if [ -n "$compose_cmd" ]; then
    ( cd "$dir" && $compose_cmd ps -q >/dev/null 2>&1 && [ -n "$($compose_cmd ps -q 2>/dev/null)" ] ) && running="yes" || true
  fi
  echo "$running"
}

# Build app list
declare -a app_dirs
while IFS= read -r f; do
  [ -z "$f" ] && continue
  d=$(dirname "$f")
  # Deduplicate
  if [ ${#app_dirs[@]} -gt 0 ] && printf '%s\n' "${app_dirs[@]}" | grep -Fxq "$d"; then continue; fi
  app_dirs+=("$d")
done < <(find_laravel_apps)

# If no Laravel apps anywhere, exit quietly so the plugin does NOT activate
if [ ${#app_dirs[@]} -eq 0 ]; then
  exit 0
fi

# Identify active app based on current working directory (nearest ancestor with artisan)
active_dir=""
search_dir="$PWD"
while [ "$search_dir" != "/" ]; do
  if [ -f "$search_dir/artisan" ]; then
    active_dir="$search_dir"
    break
  fi
  search_dir="$(cd "$search_dir/.." && pwd)"
done

# Default to the only app if just one exists
if [ -z "$active_dir" ] && [ ${#app_dirs[@]} -eq 1 ]; then
  active_dir="$(cd "${app_dirs[0]}" && pwd)"
fi

# Read Laravel intro skill
laravel_intro_content=""
if [ -f "${PLUGIN_ROOT}/skills/using-laravel-superpowers/SKILL.md" ]; then
  laravel_intro_content=$(cat "${PLUGIN_ROOT}/skills/using-laravel-superpowers/SKILL.md" 2>&1 || echo "")
fi

# Escape outputs for JSON
laravel_intro_escaped=$(echo "$laravel_intro_content" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')
warning_escaped=$(echo "$warning_message" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

#############################################
# Build output (apps summary + Sail guidance) #
#############################################

# Build listing lines with version and Sail per app
declare -a app_lines
for d in "${app_dirs[@]}"; do
  rel="${d#./}"
  [ "$rel" = "." ] && rel="."
  ver=$(get_laravel_version_for_dir "$d")
  sail=$(has_sail_for_dir "$d")
  running=$(containers_running_for_dir "$d")
  if [ "$sail" = "yes" ]; then
    line="- ${rel} (Laravel ${ver}; Sail: yes, containers: ${running})"
  else
    line="- ${rel} (Laravel ${ver}; Sail: no)"
  fi
  app_lines+=("$line")
done

apps_summary=$(printf "%s\n" "${app_lines[@]}")
apps_summary_escaped=$(echo "$apps_summary" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Active app line
active_line=""
if [ -n "$active_dir" ]; then
  # Make relative to repo root
  if [ "$active_dir" = "$PWD" ]; then
    rel_active="."
  else
    rel_active="${active_dir#${PWD}/}"
    [ -z "$rel_active" ] && rel_active="."
  fi
  ver_active=$(get_laravel_version_for_dir "$active_dir")
  active_line="Active Laravel app: ${rel_active} (Laravel ${ver_active})\n"
else
  active_line="No active Laravel app (not currently inside any app directory).\nChange working directory to one of the listed apps to focus this session.\n"
fi
active_line_escaped=$(echo "$active_line" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Sail guidance for the active app (if any)
sail_guidance=""
if [ -n "$active_dir" ] && [ "$(has_sail_for_dir "$active_dir")" = "yes" ]; then
  running_this=$(containers_running_for_dir "$active_dir")
  sail_guidance="Laravel Sail detected for active app. Prefer Sail commands inside containers to avoid host/env drift.\n\nKey mappings (Sail | Non‑Sail):\n- sail artisan … | php artisan …\n- sail composer … | composer …\n- sail php … | php …\n- sail pnpm … | pnpm … (or npm/yarn/bun)\n- sail mysql/psql/redis … | mysql/psql/redis-cli …\n\nPortable alias:\n  alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'\n"
  if [ "$running_this" = "no" ]; then
    sail_guidance+="\nInteractive safety: Sail is present but containers are not running. Before executing any host commands (php, composer, mysql, node, pnpm, npm, yarn), ask the user: \"Start Sail containers now with: 'sail up -d'? Or proceed using host tools?\" Do not run host commands unless the user explicitly opts to proceed without Sail.\nTip: Start containers: 'sail up -d' then verify: 'sail ps'.\n"
  else
    sail_guidance+="\nSail appears to be running for the active app. Use Sail commands (artisan/composer/node/db) and avoid host binaries to keep environments consistent.\n"
  fi
fi
sail_guidance_escaped=$(echo "$sail_guidance" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nLaravel projects detected in this repository. Read the onboarding below, then use the 'Skill' tool.\n\n${active_line_escaped}\nDetected apps:\n${apps_summary_escaped}\n\n${laravel_intro_escaped}\n\n${sail_guidance_escaped}\n\n${warning_escaped}\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
