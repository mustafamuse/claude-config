---
allowed-tools: Read, Glob, Grep
argument-hint: [service-name] [mahad|dugsi|shared]
description: Generate a new service following project patterns
model: opus
---

# Generate New Service

Create service: $ARGUMENTS

## Instructions

1. **Parse Arguments**
   - Extract service name and program (mahad, dugsi, or shared)
   - Default to shared if program not specified

2. **Analyze Existing Patterns**
   - Read existing services in the target directory
   - Note import patterns, logging setup, error handling
   - Identify common interface patterns

3. **Generate Service File**

   Location: `lib/services/[program]/[name]-service.ts`

   ```typescript
   /**
    * [ServiceName] Service
    *
    * [Description of what this service does]
    *
    * Responsibilities:
    * - [Responsibility 1]
    * - [Responsibility 2]
    */

   import { StripeAccountType } from '@prisma/client'
   import * as Sentry from '@sentry/nextjs'

   import { prisma } from '@/lib/db'
   import { DatabaseClient } from '@/lib/db/types'
   import { createServiceLogger } from '@/lib/logger'
   import { ActionError, ERROR_CODES } from '@/lib/errors/action-error'

   const logger = createServiceLogger('[service-name]')

   // Types
   export interface [ServiceName]Input {
     // Input type definition
   }

   export interface [ServiceName]Result {
     // Result type definition
   }

   // Service functions
   export async function [functionName](
     input: [ServiceName]Input,
     client: DatabaseClient = prisma
   ): Promise<[ServiceName]Result> {
     logger.info({ input }, 'Starting operation')

     return await Sentry.startSpan(
       {
         name: 'service.[function_name]',
         op: 'business.logic',
       },
       async () => {
         // Implementation using client for transactions
         // Throw ActionError for business logic errors
       }
     )
   }
   ```

4. **Generate Test File**

   Location: `lib/services/[program]/__tests__/[name]-service.test.ts`

   ```typescript
   import { describe, it, expect, vi, beforeEach } from 'vitest'

   import { prisma } from '@/lib/db'

   vi.mock('@/lib/db', () => ({
     prisma: {
       // Mock Prisma methods
     },
   }))

   describe('[ServiceName]', () => {
     beforeEach(() => {
       vi.clearAllMocks()
     })

     describe('[functionName]', () => {
       it('should [expected behavior]', async () => {
         // Arrange
         // Act
         // Assert
       })
     })
   })
   ```

5. **Update Index Export**
   - Add export to `lib/services/[program]/index.ts`

## Reference Services

Read these for patterns:
- `lib/services/shared/billing-service.ts` - Cross-program service pattern
- `lib/services/webhooks/webhook-service.ts` - Complex business logic
- `lib/services/mahad/enrollment-service.ts` - Program-specific service

## Service Rules

- Accept `client: DatabaseClient = prisma` parameter for transaction support
- Use `createServiceLogger()` for structured logging
- Wrap in `Sentry.startSpan()` for tracing
- Throw `ActionError` with error codes for business errors
- Export input/result interfaces
- No raw Prisma in services - delegate to query functions
