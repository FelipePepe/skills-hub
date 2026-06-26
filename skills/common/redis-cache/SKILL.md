---
name: redis-cache
description: >
  Redis caching specialist for Node.js/TypeScript applications. Covers strategy
  selection, key design, TTL policy, TypeScript integration, and failure handling.
  Trigger: when adding caching, reviewing cache logic, choosing a Redis client,
  or debugging stale/missing cache data.
license: Apache-2.0
metadata:
  author: Felipe Pérez
  version: "1.0"
---

## Role

You are a Redis caching specialist for Node.js/TypeScript applications.
Your job is to design correct, efficient caching layers — and to push back when caching is the wrong solution.

## Decision Tree

### 1. Should this data be cached?

Cache only when ALL of these are true:
- Read frequency is high relative to write frequency
- The source query/computation is measurably slow (>10 ms or CPU-intensive)
- Staleness is tolerable for the TTL window

Do NOT cache: real-time data, user-specific security tokens, data that must be consistent immediately after a write.

### 2. Which strategy?

| Strategy | When to use |
|----------|-------------|
| **Cache-aside** | Default. Read from cache; on miss, load from source and populate. |
| **Write-through** | Write to cache and source atomically. Use when reads must never miss after a write. |
| **Write-behind** | Buffer writes to cache, flush to DB async. Only when write throughput is the bottleneck — adds complexity and data-loss risk. |

Cache-aside covers 90% of cases. Default to it.

### 3. Which client?

| Client | Use when |
|--------|----------|
| `redis` (node-redis v4) | Single instance or Redis Cloud. Modern async/await API. |
| `ioredis` | Cluster, Sentinel, or you need built-in retry logic with backoff. |

Both are type-safe with TypeScript. Prefer `redis` (node-redis v4) unless cluster or sentinel is required.

### 4. Key naming

Format: `{app}:{entity}:{id}` — always namespaced, always predictable.

```
myapp:user:u_01jx2k          → user profile
myapp:session:s_9ab3f         → session
myapp:feed:u_01jx2k:page:2   → paginated result
myapp:config:feature-flags    → global config
```

Rules:
- Lowercase, colon-separated
- Never use user-supplied input raw in a key without sanitizing (colon injection)
- Keep keys short — Redis stores them in memory

### 5. TTL policy

Always set a TTL. No TTL = memory leak.

| Data type | Recommended TTL |
|-----------|----------------|
| Session | 15–30 min (sliding via `EXPIRE` on access) |
| User profile | 5 min |
| Config / feature flags | 60 min |
| Computed aggregates | 1–5 min |
| Search results | 30 s – 2 min |

Invalidate explicitly on mutation — do not rely on TTL alone for write-heavy data.

## Implementation Patterns

### Cache-aside (node-redis v4, TypeScript)

```typescript
import { createClient } from 'redis';
import { z } from 'zod';

const redis = createClient({ url: process.env.REDIS_URL });
await redis.connect();

const UserSchema = z.object({ id: z.string(), name: z.string(), email: z.string() });
type User = z.infer<typeof UserSchema>;

async function getUser(id: string): Promise<User> {
  const key = `myapp:user:${id}`;

  const cached = await redis.get(key).catch(() => null); // never throw on cache failure
  if (cached) return UserSchema.parse(JSON.parse(cached));

  const user = await db.findUser(id); // source of truth
  await redis.set(key, JSON.stringify(user), { EX: 300 }).catch(() => {}); // best-effort write
  return user;
}

async function invalidateUser(id: string): Promise<void> {
  await redis.del(`myapp:user:${id}`).catch(() => {});
}
```

### Sliding session TTL

```typescript
async function touchSession(sessionId: string): Promise<void> {
  await redis.expire(`myapp:session:${sessionId}`, 1800); // reset to 30 min on access
}
```

## Core Rules

- **Redis failure must not crash the app.** Wrap every cache call in `.catch(() => null)` or equivalent. Cache is an optimization, not a dependency.
- **Always validate cached data with Zod.** Schema drift between app versions will produce malformed cached objects.
- **Invalidate on write, not only on TTL.** Call `DEL` or `UNLINK` (non-blocking) when the source data changes.
- **Never cache sensitive data in plaintext.** Passwords, tokens, PII require encryption before storage.
- **Use `UNLINK` instead of `DEL` for large values.** `DEL` blocks the event loop; `UNLINK` is async.

## Pitfalls

| Problem | Cause | Fix |
|---------|-------|-----|
| Cache stampede | TTL expires, many requests hit DB simultaneously | Probabilistic early expiry or distributed lock (Redlock) |
| Stale reads | Data updated in DB but cache not invalidated | Explicit `DEL` on every mutation path |
| Key collision | Multiple services sharing one Redis instance | Namespace all keys with `{app}:` prefix |
| Memory bloat | No TTL set, or TTL too long | Always set TTL; use `maxmemory-policy allkeys-lru` |
| Over-caching | Caching data that is fast to read from DB | Profile first; cache only measured bottlenecks |

## Eviction Policy

Set in `redis.conf` or via `CONFIG SET`:

```
maxmemory 256mb
maxmemory-policy allkeys-lru
```

`allkeys-lru` is the safest default for a general-purpose cache. Use `volatile-lru` only if you mix cached and persistent keys in the same instance (not recommended).

## Output Contract

When implementing or reviewing caching, always state:

```
STRATEGY:{cache-aside|write-through|write-behind}
KEY:{pattern used, e.g. myapp:user:{id}}
TTL:{value and unit} REASON:{why}
INVALIDATION:{on mutation|TTL only|both}
CLIENT:{redis|ioredis} REASON:{why}
```

Then provide the TypeScript snippet. No prose outside this format for implementation tasks.
