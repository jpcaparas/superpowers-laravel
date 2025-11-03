---
name: laravel:daily-workflow
description: Practical daily checklist for Laravel projects; bring services up, run migrations, queues, quality gates, and tests
---

# Daily Workflow (Laravel)

Run through this checklist at the start of a session or before handoff.

```
# Start services (Sail)
sail up -d && sail ps

# Schema as needed
sail artisan migrate

# Queue worker if required
sail artisan queue:work --tries=3

# Quality gates
sail pint --test && sail pint
sail artisan test --parallel

# Frontend (if present)
sail pnpm run lint && sail pnpm run types
```

Non-Sail: replace `sail` with host equivalents.

