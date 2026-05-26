---
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [threshold-percentage]
description: Analyze test coverage and identify gaps
model: sonnet
---

# Test Coverage Analysis

Analyze test coverage with threshold: $ARGUMENTS (default: 80%)

## Instructions

1. **Generate Coverage Report**
   ```bash
   npx vitest run --coverage
   ```

2. **Parse Coverage Data**
   - Read coverage output or `/coverage/coverage-summary.json` if available
   - Extract line, function, branch, and statement coverage

3. **Identify Gaps**
   - List files below threshold with specific uncovered lines
   - Prioritize by:
     - Critical paths (services, actions, webhooks)
     - Recently modified files
     - Complexity (files with many branches)

4. **Generate Recommendations**
   - Suggest specific test cases for uncovered code
   - Show example test patterns from existing tests in codebase
   - Identify dead code that may not need coverage

## Output Format

```
## Coverage Summary
| Category   | Coverage | Status |
|------------|----------|--------|
| Lines      | 78.5%    | ...    |
| Functions  | 82.1%    | ...    |
| Branches   | 71.2%    | ...    |
| Statements | 79.3%    | ...    |

## Files Below Threshold
1. lib/services/webhooks/webhook-service.ts (65%)
   - Lines 45-67: handlePaymentMethodCapture error path
   - Lines 120-145: subscription edge cases

## Recommended Tests
[Specific test suggestions based on uncovered code]
```

## Priority Areas for This Codebase

- `lib/services/webhooks/` - Critical payment processing
- `lib/services/shared/` - Cross-program billing logic
- `app/admin/*/actions.ts` - Server actions
- `lib/db/queries/` - Database operations
