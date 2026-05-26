---
allowed-tools: Bash, Read, Grep, mcp__prisma-local__Prisma-Studio
argument-hint: [table-name]
description: Inspect database table schema and relationships
model: sonnet
---

# Database Table Inspector

Inspect table: $ARGUMENTS

## Instructions

1. **Parse Schema**
   - Read `prisma/schema.prisma`
   - Find model definition for `$ARGUMENTS`
   - Extract fields, types, relations, indexes

2. **Analyze Relationships**
   - Map foreign keys and back-references
   - Show related models
   - Display relation cardinality (1:1, 1:many, many:many)

3. **Show Indexes**
   - List all indexes on the table
   - Identify composite indexes
   - Note unique constraints

4. **Query Patterns**
   - Show example Prisma queries for this model
   - Reference existing queries in `/lib/db/queries/`
   - Note any Prisma validators defined for this model

## Output Format

```
## Model: [TableName]

### Fields
| Field          | Type             | Constraints        |
|----------------|------------------|-------------------|
| id             | String           | @id @default(uuid) |
| ...            | ...              | ...               |

### Relations
- RelatedModel (cardinality) via foreignKey

### Indexes
- @@index([field1, field2])
- @@unique([field1, field2])

### Example Queries
[Prisma query examples for common operations]

### Existing Query Functions
[Links to lib/db/queries/ functions for this model]
```

## Key Models in This Codebase

- `Person` - Central identity model
- `ProgramProfile` - Links Person to program (Mahad, Dugsi)
- `Enrollment` - Student enrollment in batches (Mahad)
- `BillingAccount` - Stripe customer data
- `Subscription` - Stripe subscription records
- `BillingAssignment` - Links subscriptions to profiles
