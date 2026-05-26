---
allowed-tools: Read, Grep, Glob, Bash
argument-hint: [error-message-or-code]
description: Investigate and diagnose errors
model: opus
---

# Error Investigation

Investigate error: $ARGUMENTS

## Instructions

1. **Search Codebase**
   - Search for error message in source files
   - Find where error is thrown or caught
   - Identify error type (Prisma, Stripe, Zod, ActionError)

2. **Error Type Analysis**

   ### Prisma Errors (P2xxx)
   | Code | Meaning | Common Fix |
   |------|---------|------------|
   | P2002 | Unique constraint violation | Check for duplicates |
   | P2025 | Record not found | Verify ID exists |
   | P2003 | Foreign key constraint | Check related records |
   | P2024 | Timeout | Optimize query or increase timeout |

   ### Stripe Errors
   - Check error code in Stripe docs
   - Verify webhook signature
   - Check customer/subscription state
   - Confirm correct Stripe account (Mahad vs Dugsi)

   ### Zod Validation Errors
   - Parse validation errors
   - Show expected vs received types
   - Check schema definition

   ### ActionError
   - Find error code in `lib/errors/action-error.ts`
   - Trace to service that threw it
   - Check business logic conditions

3. **Trace Error Path**
   - Find the function that throws
   - Trace call stack through services
   - Identify input that caused error

4. **Check Related Code**
   - Look at error handling in callers
   - Check if error is logged properly
   - Verify Sentry capture

## Output Format

```
## Error Analysis: [Error Message/Code]

### Error Type
[Prisma/Stripe/Zod/ActionError/Unknown]

### Location
File: /path/to/file.ts
Line: 123
Function: functionName

### Root Cause
[Explanation of why this error occurs]

### Call Stack
1. Entry point (route/action)
2. Service function
3. Query/operation <- Error thrown here

### Suggested Fix
[Code changes to fix the issue]

### Prevention
[How to prevent this error in future]
```

## Common Error Patterns in This Codebase

| Error | Location | Typical Cause |
|-------|----------|---------------|
| "No person found" | webhook-service.ts | Checkout without matching profile |
| "Subscription has no items" | webhook-service.ts | Invalid Stripe subscription |
| "Invalid amount" | billing-service.ts | Price.unit_amount is 0 or null |
| "Already enrolled" | enrollment-service.ts | Duplicate enrollment attempt |
