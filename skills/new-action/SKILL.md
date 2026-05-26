---
allowed-tools: Read, Glob, Grep
argument-hint: [action-name] [app-route]
description: Generate a new server action following project patterns
model: opus
---

# Generate New Server Action

Create action: $ARGUMENTS

## Instructions

1. **Parse Arguments**
   - Extract action name and target route (e.g., `createStudent admin/mahad`)
   - Determine if adding to existing actions file or creating new

2. **Analyze Existing Actions**
   - Read actions in target route directory
   - Note validation patterns, error handling, revalidation
   - Check for existing Zod schemas to reuse

3. **Generate Action**

   ```typescript
   'use server'

   import { revalidatePath } from 'next/cache'
   import * as Sentry from '@sentry/nextjs'
   import { z } from 'zod'

   import { createActionLogger, logError } from '@/lib/logger'
   import { ActionResult } from '@/lib/utils/action-helpers'
   // Import relevant service

   const logger = createActionLogger('[actionName]')

   // Zod schema for input validation
   const [actionName]Schema = z.object({
     // Define input shape
   })

   type [ActionName]Input = z.infer<typeof [actionName]Schema>

   /**
    * [Action description]
    */
   export async function [actionName](
     input: [ActionName]Input
   ): Promise<ActionResult<[OutputType]>> {
     return await Sentry.startSpan(
       {
         name: 'action.[action_name]',
         op: 'server.action',
       },
       async () => {
         try {
           // Validate input
           const validated = [actionName]Schema.parse(input)

           logger.info({ input: validated }, 'Starting action')

           // Call service
           const result = await someService(validated)

           // Revalidate cache
           revalidatePath('/path/to/revalidate')

           return { success: true, data: result }
         } catch (error) {
           await logError(logger, error, 'Action failed', { input })

           // Handle Zod validation errors
           if (error instanceof z.ZodError) {
             return {
               success: false,
               errors: error.flatten().fieldErrors,
             }
           }

           return {
             success: false,
             error: error instanceof Error ? error.message : 'Unknown error',
           }
         }
       }
     )
   }
   ```

4. **ActionResult Type Pattern**

   ```typescript
   type ActionResult<T> =
     | { success: true; data: T }
     | { success: false; error: string; errors?: Record<string, string[]> }
   ```

## Reference Actions

Read these for patterns:
- `app/admin/dugsi/actions.ts` - Multiple actions with Prisma error handling
- `app/admin/link-subscriptions/actions.ts` - Stripe-related actions
- `app/admin/mahad/cohorts/_actions/index.ts` - Comprehensive error handling

## Action Rules

- Always use `'use server'` directive
- Always return `ActionResult<T>`
- Validate input with Zod before any operations
- Use `revalidatePath()` after mutations
- Log errors with structured context
- Handle both Zod and Prisma errors specifically
- Keep actions thin - delegate to services
