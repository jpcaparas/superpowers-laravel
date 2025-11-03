# Laravel Installation Notes (Version-Agnostic)

This summary distills the official Installation guide into version-agnostic steps you can apply across supported Laravel versions.

- Requirements
  - PHP with common extensions enabled (mbstring, openssl, pdo, tokenizer, xml, curl, fileinfo, etc.)
  - Composer available on PATH
  - Database server and PHP driver installed (MySQL/MariaDB, PostgreSQL, SQLite, SQL Server, etc.)
  - Node.js + package manager (pnpm/npm/yarn) for asset bundling

- Creating Projects
  - Via Composer: `composer create-project laravel/laravel your-app`
  - Or clone an existing repo, then install dependencies: `composer install`

- Environment
  - Copy `.env.example` to `.env` and set app key, database credentials, mail, cache, and queue backends
  - Generate key: `php artisan key:generate` (or `sail artisan key:generate`)

- Local Development
  - Use Laravel Sail for a portable Docker setup, or run PHP/DB locally on your host
  - Migrate database: `php artisan migrate` (or `sail artisan migrate`)
  - Run dev server / Vite: `php artisan serve` / `pnpm run dev` (or Sail equivalents)

- Optional Services
  - Queues (Redis/database), Horizon, Mail (Mailpit), Storage (S3-compatible providers), Search, etc.

- Production
  - Configure web server (Nginx/Apache), PHP-FPM, queues, scheduler
  - Optimize config/routes/views and use environment-specific credentials

This repository’s Laravel skills assume these fundamentals and provide Sail/non‑Sail command pairs throughout.
