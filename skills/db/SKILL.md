---
allowed-tools: Bash, Read, Grep, Glob, mcp__prisma-local__migrate-status, mcp__prisma-local__migrate-dev, mcp__prisma-local__Prisma-Studio
argument-hint: [status|migrate|studio|seed|diff]
description: Prisma database management workflow
model: sonnet
---

# Database Management

Execute database action: $ARGUMENTS

## Current State

- Migration status: !`npx prisma migrate status 2>&1 | tail -10`
- Schema location: prisma/schema.prisma

## Actions

### `status` (default)
Show migration status and pending changes:
1. Run `npx prisma migrate status`
2. Check for schema drift
3. Show recent migrations

### `migrate [name]`
Create and apply a new migration:
1. Verify schema changes with `npx prisma format`
2. Create migration: `npx prisma migrate dev --name [name]`
3. Generate client: `npx prisma generate`
4. Show migration summary

### `studio`
Open Prisma Studio for visual database browsing:
- Use MCP tool: `mcp__prisma-local__Prisma-Studio`
- Opens at http://localhost:5555

### `seed`
Seed database with test data:
1. Run `npm run seed` or `npx prisma db seed`
2. Verify data with quick counts

### `diff`
Show schema diff:
1. Compare current schema to database
2. Highlight pending changes
3. Suggest migration name

## Safety Checks

- Verify environment before destructive operations
- Check DATABASE_URL doesn't contain "prod" or "production"
- Never run `prisma migrate reset` in production
- Backup reminders for production changes

## Common Prisma Commands Reference

```bash
npx prisma migrate status     # Check migration state
npx prisma migrate dev        # Apply migrations (dev)
npx prisma migrate deploy     # Apply migrations (prod)
npx prisma generate           # Regenerate client
npx prisma format             # Format schema file
npx prisma studio             # Visual database browser
npx prisma db pull            # Pull schema from database
```
