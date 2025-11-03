# Integrating Laravel Superpowers in Any Project

This repo is a Claude Code plugin that adds Laravel-aware skills without forcing Sail. It works in any Laravel app. You can install it as a plugin or copy skills directly.

## Option A: Install as Claude Code Plugin

```
/plugin marketplace add jpcaparas/superpowers-laravel
/plugin install superpowers-laravel@superpowers-laravel-marketplace
```

On session start, if your repo contains `artisan` or `composer.json` referencing `laravel/framework`, the plugin will load the `using-laravel-superpowers` introduction. If `laravel/sail` is declared in `composer.json`, the plugin adds Sail guidance and enforces interactive safety when containers are not running (see below).

## Option B: Copy Skills Locally

Copy selected folders from `skills/` into your project’s `.claude/skills/` keeping the same structure. Claude will auto-discover them.

Recommended minimum set:

- `using-laravel-superpowers`
- `runner-selection`
- `tdd-with-pest`
- `migrations-and-factories`
- `quality-checks`

## Runner Guidance

Define this portable alias in your shell:

```
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
```

Use `sail ...` when available, otherwise `php artisan`, `composer`, and `pnpm` on host.

## Interactive Runner Gating

When `laravel/sail` is present in `composer.json` but containers are not running, the assistant will not run host PHP/Composer/DB/Node commands without asking. You’ll be prompted to either:

- Start Sail: `sail up -d` (recommended), or
- Proceed using host tools for this session.

The assistant will prompt and honor your choice for this session.

## Quality Gates

- Pint: `sail pint --test` then `sail pint` (or `vendor/bin/pint --test` then `vendor/bin/pint`)
- Static Analysis: PHPStan or Psalm (`sail vendor/bin/phpstan` or `sail vendor/bin/psalm`; or host `vendor/bin/phpstan|psalm`)
- Tests: `sail artisan test --parallel` (or `php artisan test --parallel`)
- Frontend: `sail pnpm run lint` and `sail pnpm run types` (or `pnpm run lint` and `pnpm run types`)

## Notes

- These skills are intentionally generic. If your team has a bundled `check` command, keep using it; otherwise use the provided pairs.
- Nothing here is Sail-only. All skills include non-Sail equivalents.
