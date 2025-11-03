---
name: laravel:performance-caching
description: Use route/config/view and value/query caching to reduce work; plan invalidation and durations carefully
---

# Caching Basics

## Framework caches

```
php artisan route:cache
php artisan config:cache
php artisan view:cache
```

Clear with the corresponding `clear` commands when needed in deployments.

## Values and queries

```php
Cache::remember("post:{$id}", 600, fn () => Post::findOrFail($id));
```

- Choose TTLs based on freshness requirements
- Invalidate explicitly on writes when correctness matters

