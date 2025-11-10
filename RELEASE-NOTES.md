# Laravel Superpowers — Release Notes

## v0.1.5 (2025-11-11)

Added five new best practice skills based on recommendations from https://saasykit.com/blog/laravel-best-practices to provide comprehensive coverage of Laravel development patterns.

### Added (Skills)

- **Routes Best Practices** (`routes-best-practices`) - Keep routes clean and focused on mapping requests to controllers, avoiding business logic in route files
- **Data Chunking for Large Datasets** (`data-chunking-large-datasets`) - Handle large datasets efficiently with `chunk()`, `chunkById()`, `lazy()`, and `cursor()` methods
- **Internationalization and Translation** (`internationalization-and-translation`) - Build with i18n in mind from day one using Laravel's translation helpers
- **Constants and Configuration** (`constants-and-configuration`) - Replace hardcoded values with constants, enums, and configuration for better maintainability
- **Documentation Best Practices** (`documentation-best-practices`) - Write meaningful documentation that explains "why" not "what", focusing on complex business logic

### Notes

These additions complement the existing comprehensive skill set by filling gaps identified from the SaaSykit Laravel best practices guide. All new skills include extensive examples, anti-patterns, and real-world use cases.

## v0.1.4 (2025-11-04)

Monorepo-aware SessionStart with multi-app detection, per-app version reporting, and scoped Sail guidance.

### Monorepo Support

- Recursively discovers Laravel apps by locating `artisan` anywhere in the repo (ignores heavy/irrelevant folders like `vendor/`, `node_modules/`, `storage/`, VCS/IDE folders).
- Supports multiple Laravel apps in a single repository. The hook lists all detected apps with:
  - Relative path
  - Laravel version (from `composer.lock` via `jq` when available, with fallback to `composer.json` constraint or a portable parser)
  - Sail availability, and whether containers appear to be running
- Determines the “active” app based on the current working directory; if only one app exists, it becomes active automatically.
- Emits Sail guidance and interactive safety for the active app only, to avoid cross-app confusion.

### Testing

- Extended `scripts/test_session_start.sh` to cover:
  - Non-Laravel repo bailout
  - Single app (no Sail)
  - Sail present but containers stopped (interactive safety messaging)
  - Sail present with containers running
  - Monorepo with two nested apps on different Laravel versions
  - Monorepo where hook runs inside a nested app (active app semantics)
- CI workflow `.github/workflows/test-session-start.yml` continues to run this script; no changes required beyond the added scenarios.

### Notes

- If `jq` is unavailable, the hook falls back to a portable parser for version detection; output may show version constraints or `unknown` in minimal setups.

## v0.1.2 (2025-11-04)

Docs sweep across Laravel 11.x and 12.x, with new skills matching the intersection of stable patterns. Also consolidated duplicates and kept commands thin.

### Added (Skills)

- Form Requests & Validation (`laravel:form-requests`)
- Policies & Authorization (`laravel:policies-and-authorization`)
- Eloquent Relationships & Loading (`laravel:eloquent-relationships`)
- Transactions & Consistency (`laravel:transactions-and-consistency`)
- HTTP Client Resilience (`laravel:http-client-resilience`)
- Task Scheduling (`laravel:task-scheduling`)
- API Resources & Pagination (`laravel:api-resources-and-pagination`)
- Blade Components & Layouts (`laravel:blade-components-and-layouts`)
- Filesystem Uploads & URLs (`laravel:filesystem-uploads`)
- Rate Limiting & Throttle (`laravel:rate-limiting`)
- Exception Handling & Logging (`laravel:exception-handling-and-logging`)

Matching command wrappers were added under `commands/` using the existing convention.

### Changed

- Unified caching guidance into `laravel:performance-caching` (added tags, locks, invalidation best‑practices). Removed the duplicate cache strategies skill/command.
- De‑duplicated Eloquent guidance: relationships skill now references `laravel:performance-eager-loading` for N+1 detection/measurement.

### Removed

- Subagents that duplicated skills (Form Request Builder, Policy Planner, Transaction Auditor, API Resource Designer). The repo keeps subagents minimal; the controller cleaner remains.
- Redundant Sail prompt skill (covered by runner selection and integration docs).

### Docs

- Summary of 11.x/12.x intersection captured within the new skills themselves.

## v0.1.1 (2025-11-04)

Smarter Laravel detection, Sail via binary presence, and safer command guidance.

### Detection & Safety

- SessionStart now bails out cleanly for non‑Laravel repos (no output), ensuring the plugin does NOT activate outside Laravel projects.
- Sail is detected by executable presence only: `vendor/bin/sail` (or a top‑level `./sail` helper). We no longer parse `composer.json` or rely on `jq` for Sail checks.
- Determines whether containers are running via `docker compose ps` / `docker-compose ps` (unchanged).
- Injects guidance to prefer Sail commands when Sail is available; clearly maps Sail vs host command pairs (artisan/composer/php/node/db).
- Interactive safety: when Sail is available but containers are not running, the assistant must ask whether to start containers (`sail up -d`) or proceed using host tools—no host PHP/Composer/DB/Node commands should run until the user chooses.

### Docs & Screenshots

- README now includes screenshots of SessionStart with and without Sail.

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
