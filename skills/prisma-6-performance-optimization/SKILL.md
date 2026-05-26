---
name: prisma-6-performance-optimization
description: Prisma 6 performance and optimization best practices. Use when implementing TypedSQL queries, optimizing raw SQL performance, configuring connection pooling, or eliminating n+1 query problems with relationLoadStrategy join operations.
---

# Prisma 6 Performance Optimization

Performance-focused patterns for Prisma 6 with emphasis on TypedSQL, raw queries, and connection optimization.

## When to Apply

- Optimizing slow queries with TypedSQL and raw SQL
- Eliminating n+1 query problems with relationLoadStrategy
- Configuring connection pooling for serverless environments
- Migrating from legacy raw queries to TypedSQL

## Critical Rules

**TypedSQL over $queryRaw**: Always prefer TypedSQL for type safety and performance

```typescript
// WRONG - No type safety, SQL injection risk
const users = await prisma.$queryRawUnsafe(
  `SELECT * FROM User WHERE email LIKE '%${domain}'`
)

// RIGHT - Type-safe, generated from SQL file
import { getUsersByDomain } from './generated/prisma/sql'
const users = await prisma.$queryRawTyped(getUsersByDomain(domain))
```

**relationLoadStrategy join**: Use join strategy to eliminate n+1 queries

```typescript
// WRONG - Multiple database queries (n+1 problem)
const users = await prisma.user.findMany()
for (const user of users) {
  user.posts = await prisma.post.findMany({ where: { authorId: user.id } })
}

// RIGHT - Single query with join strategy
const users = await prisma.user.findMany({
  relationLoadStrategy: 'join',
  include: { posts: true }
})
```

## Key Patterns

### TypedSQL Setup and Usage

```prisma
// schema.prisma
generator client {
  provider = "prisma-client"
  previewFeatures = ["typedSql"]
}
```

```sql
-- prisma/sql/getUserStats.sql
-- @param {String} $1:email
SELECT u.id, u.name, COUNT(p.id) as post_count
FROM "User" u
LEFT JOIN "Post" p ON u.id = p."authorId"
WHERE u.email = $1
GROUP BY u.id, u.name;
```

```typescript
import { getUserStats } from './generated/prisma/sql'

const stats = await prisma.$queryRawTyped(getUserStats('user@example.com'))
// Fully typed result based on SQL query
```

### Performance-Optimized Raw Queries

```typescript
// Parameterized queries prevent SQL injection
const users = await prisma.$queryRaw<User[]>`
  SELECT id, email, name FROM "User" 
  WHERE "createdAt" > ${new Date('2024-01-01')}
  ORDER BY "createdAt" DESC
  LIMIT 100
`

// Dynamic safe queries with Prisma.sql
const orderBy = 'createdAt'
const users = await prisma.$queryRaw`
  SELECT * FROM "User" 
  ORDER BY ${Prisma.raw(`"${orderBy}"`)} DESC
`

// Bulk operations for better performance
const affectedRows = await prisma.$executeRaw`
  UPDATE "Post" SET published = true 
  WHERE "authorId" IN (${Prisma.join(authorIds)})
`
```

### Connection Pooling Optimization

```typescript
// Prisma Accelerate with connection pooling
import { withAccelerate } from '@prisma/extension-accelerate'

const prisma = new PrismaClient().$extends(withAccelerate())

// Performance monitoring setup
async function measureQueryPerformance() {
  const timings = []
  const LOOP_LENGTH = 10000

  // Warm-up query
  await prisma.user.findMany({ take: 20 })

  for (let i = 0; i < LOOP_LENGTH; i++) {
    const start = Date.now()
    await prisma.user.findMany({ take: 20 })
    timings.push(Date.now() - start)
  }

  const avg = timings.reduce((a, b) => a + b) / timings.length
  console.log(`Average query time: ${avg}ms`)
}
```

### Relation Load Strategy Optimization

```typescript
// Use join for single-query performance
const usersWithPosts = await prisma.user.findMany({
  relationLoadStrategy: 'join', // Default in Prisma 6+
  include: { posts: true }
})

// Works with select as well
const userData = await prisma.user.findMany({
  relationLoadStrategy: 'join',
  select: {
    id: true,
    posts: { select: { title: true } }
  }
})
```

### Field Selection for Reduced Payload

```typescript
// Select only required fields
const users = await prisma.user.findMany({
  select: {
    id: true,
    email: true,
    profile: {
      select: {
        firstName: true,
        lastName: true
      }
    }
  },
  take: 100
})
```

## Connection Pool Configuration

```typescript
// Driver adapter configuration for Prisma v6 compatibility
import { PrismaPg } from '@prisma/adapter-pg'

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
  connectionTimeoutMillis: 5_000,    // v6 default
  idleTimeoutMillis: 300_000,        // v6 default
})

// Connection string parameters
// postgresql://user:pass@host:5432/db?connection_limit=10&pool_timeout=20
```

## Common Mistakes

- **Using $queryRawUnsafe without parameters** — Always use parameterized queries or TypedSQL
- **Missing relationLoadStrategy** — Explicitly set 'join' to avoid n+1 queries  
- **Over-selecting data** — Use select to limit fields and reduce payload size
- **Ignoring connection limits** — Configure pool size based on database capacity
- **Not measuring performance** — Implement monitoring to track query performance metrics