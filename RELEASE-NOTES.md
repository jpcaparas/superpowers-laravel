# Laravel Superpowers — Release Notes

## v0.1.1 (2025-11-04)

Smarter Laravel Sail detection and safer command guidance.

### Sail Detection & Safety

- SessionStart hook now detects Sail deterministically via `composer.json` (checks `require-dev` and `require` for `laravel/sail`; uses `jq` when available, falls back to grep).
- Detects Sail binary presence (`./sail` or `vendor/bin/sail`) and whether containers are running via `docker compose ps` / `docker-compose ps`.
- Injects guidance to prefer Sail commands when Sail is declared; clearly maps Sail vs host command pairs (artisan/composer/php/node/db).
- Interactive safety: when Sail is declared but containers are not running, the assistant must ask whether to start containers (`sail up -d`) or proceed using host tools—no host PHP/Composer/DB/Node commands should run until the user chooses.

### Docs & Skills Cleanup

- Replaced hardcoded Sail-only lines with Sail/non‑Sail pairs:
  - `skills/migrations-and-factories/SKILL.md`
  - `skills/queues-and-horizon/SKILL.md`
  - `skills/daily-workflow/SKILL.md`
  - `skills/quality-checks/SKILL.md`
- Ensured quality/static analysis and frontend checks include host equivalents.

### New Skill

- [Removed] Previously documented interactive Sail prompt skill. Interactive safety is still enforced by the assistant when Sail is declared but containers are not running.

### Reference

- Common Sail commands supported: `sail up|stop|restart|ps`, `sail artisan …`, `sail php …`, `sail composer …`, `sail node|npm|npx|pnpm|pnpx|yarn|bun|bunx …`, `sail mysql|mariadb|psql|mongodb|redis|valkey`, `sail test|phpunit|pest|pint|dusk`.

## v0.1.0 (2025-11-03)

First public release of Laravel Superpowers — a Laravel‑focused skills library for Claude Code. It brings proven workflows (TDD, debugging, planning) together with Laravel‑aware guidance that stays platform‑agnostic (works with or without Sail).

### Highlights

- Plugin identity and marketplace metadata for the Laravel fork
  - Renamed plugin to `superpowers-laravel` and pointed metadata to `jpcaparas/superpowers-laravel`
  - Added local marketplace entry to simplify install during development

- Laravel‑aware SessionStart
  - Startup hook auto‑detects Laravel projects (via `artisan` or `composer.json` with `laravel/framework`)
  - Injects a concise “Using Superpowers in Laravel Projects” introduction when Laravel is detected

- New Laravel skills (all Sail/non‑Sail compatible)
  - Onboarding & Runner (using‑laravel‑superpowers, runner‑selection)
  - Development & Testing (tdd‑with‑pest, migrations‑and‑factories)
  - Quality & Operations (quality‑checks, queues‑and‑horizon)
  - Architecture & Complexity (ports‑and‑adapters, template‑method‑and‑plugins, complexity‑guardrails)

- Optional skills (scaffolding for growing teams)
  - Nova resource patterns; Horizon dashboards/metrics; E2E Playwright patterns
  - API surface evolution; Config/Env storage strategy

- Key commands (plugin‑namespaced)
  - `/superpowers-laravel:brainstorm`, `/superpowers-laravel:write-plan`, `/superpowers-laravel:execute-plan`
  - `/superpowers-laravel:laravel-check`, `/superpowers-laravel:laravel-tdd`

- Documentation
  - Updated README for Laravel‑first usage (now includes repo logo)
  - Added Related Tools note for Laravel Boost (complementary if installed)
  - New integration guide: `docs/laravel/INTEGRATION.md`
  - New installation notes (version‑agnostic): `docs/laravel/INSTALLATION-NOTES.md`

### Files

- Hook: `hooks/session-start.sh` (Laravel detection + onboarding)
- Skills live under `skills/`; commands under `commands/`
- Docs: `docs/laravel/INTEGRATION.md`, `docs/laravel/INSTALLATION-NOTES.md`

### New skills inspired by Clean Coders Guide

- Controller cleanup; performance (eager loading, select columns, caching); dependency trimming
- Helpers; interfaces + DI; strategy; controller testing

### Commands

- Examples provided for core flows and a few advanced skills; run `/help` to see everything available in your environment.

### Maintenance

- Moved Laravel skills from `skills/laravel/**` to first‑party `skills/**`
- Removed empty directories after consolidation
- Cleaned references in README and docs to reflect new locations and command namespace
- Added CI validation for skills structure and plugin conventions: `.github/workflows/validate-skills.yml`

### Notes

- All skills intentionally include Sail/non‑Sail command pairs to avoid platform lock‑in.
- Insights is treated as optional; Pint and static analysis (PHPStan/Psalm) are encouraged as baselines.
