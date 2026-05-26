---
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [file|directory|--watch|--coverage|--ui]
description: Run Vitest tests with intelligent target detection
model: sonnet
---

# Run Tests

Execute Vitest tests for: $ARGUMENTS

## Current Test State

- Test files found: !`find . -name "*.test.ts" -o -name "*.test.tsx" | grep -v node_modules | wc -l`
- Last modified tests: !`find . -name "*.test.ts" -o -name "*.test.tsx" | grep -v node_modules | xargs ls -t 2>/dev/null | head -5`

## Instructions

1. **Parse Arguments**
   - If `$ARGUMENTS` is empty: run `npm run test:run`
   - If `--watch`: run `npm run test`
   - If `--coverage`: run `npx vitest run --coverage`
   - If `--ui`: run `npm run test:ui`
   - If a file path: run `npx vitest run $ARGUMENTS`
   - If a directory: run `npx vitest run $ARGUMENTS/`

2. **Smart Target Detection**
   - If given a source file (e.g., `lib/services/dugsi/payment-service.ts`), find related tests
   - Look for `__tests__/` directory siblings or `.test.ts` files
   - Example: `lib/services/dugsi/payment-service.ts` → `lib/services/dugsi/__tests__/payment-service.test.ts`

3. **Results Analysis**
   - Parse test output and summarize:
     - Total tests: passed/failed/skipped
     - Failed test details with file locations
     - Suggestions for fixing failures

4. **Coverage Reporting** (if --coverage)
   - Show coverage percentages by category
   - Identify uncovered lines in changed files

## Example Usage

```bash
/test                           # Run all tests
/test --watch                   # Watch mode
/test --coverage                # With coverage report
/test lib/services/dugsi        # Run dugsi service tests
/test app/api/webhook           # Run webhook tests
```

## Test Patterns in This Codebase

- Tests colocated in `__tests__/` directories
- Using Vitest with happy-dom environment
- Mocking with `vi.mock()`
- Common patterns: `describe`, `it`, `expect`, `beforeEach`
