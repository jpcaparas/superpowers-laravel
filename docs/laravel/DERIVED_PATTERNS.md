# Laravel 11.x and 12.x — Common Good Patterns (Skills Map)

This document summarizes patterns present in both Laravel 11.x and 12.x documentation and maps them to skills, subagents, and commands provided by this plugin. It focuses on stable areas that change little between versions and are broadly applicable.

## Core Skills (Docs Intersection)

- Form Requests and Validation → `skills/form-requests-and-validation/SKILL.md`
- Policies and Authorization → `skills/policies-and-authorization/SKILL.md`
- Eloquent Relationships and Loading → `skills/eloquent-relationships-and-loading/SKILL.md`
- Transactions and Consistency → `skills/transactions-and-consistency/SKILL.md`
- HTTP Client Resilience → `skills/http-client-resilience/SKILL.md`
- Task Scheduling → `skills/task-scheduling/SKILL.md`
- API Resources and Pagination → `skills/api-resources-and-pagination/SKILL.md`
- Blade Components and Layouts → `skills/blade-components-and-layouts/SKILL.md`
- Performance Caching (with tags/locks/invalidation) → `skills/performance-caching/SKILL.md`
- Exception Handling and Logging → `skills/exception-handling-and-logging/SKILL.md`
- Filesystem Uploads and URLs → `skills/filesystem-uploads-and-urls/SKILL.md`
- Rate Limiting and Throttle → `skills/rate-limiting-and-throttle/SKILL.md`

These complement existing skills such as runner selection, migrations/factories, queues/Horizon, performance (eager loading, select columns, caching), and TDD.

## Subagents

This repo keeps subagents minimal to avoid overlap with skills. Use the existing controller-focused subagent:

- Controller Cleaner → `agents/laravel-controller-cleaner.md`

Other topics above are covered as skills rather than subagents.

## Command Wrappers

Each new skill has a matching command in `commands/` following the existing convention. For example, `commands/laravel-form-requests.md` activates `laravel:form-requests`.

## Notes on Source Material

The above patterns are stable across 11.x and 12.x. Version‑specific features like Pulse, MCP, or newer concurrency helpers are intentionally excluded from the intersection.
