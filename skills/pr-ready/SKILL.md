---
allowed-tools: Bash, Read, Grep, Glob
argument-hint:
description: Pre-PR checklist and validation
model: sonnet
---

# PR Readiness Check

Validate code is ready for pull request.

## Automated Checks

Run all validation checks:

1. **Type Check**
   ```bash
   npm run typecheck
   ```

2. **Lint**
   ```bash
   npm run lint
   ```

3. **Format Check**
   ```bash
   npx prettier --check "**/*.{ts,tsx,js,jsx,json,md}"
   ```

4. **Tests**
   ```bash
   npm run test:run
   ```

5. **Build**
   ```bash
   npm run build
   ```

## Output Summary

```
## PR Readiness Report

### Automated Checks
| Check      | Status | Details |
|------------|--------|---------|
| TypeCheck  | ...    | ...     |
| Lint       | ...    | ...     |
| Format     | ...    | ...     |
| Tests      | ...    | ...     |
| Build      | ...    | ...     |

### Issues Found
[List any failures with details]

### Ready for PR: Yes/No
```

## Manual Review Checklist

After automated checks pass, verify:

- [ ] All tests pass
- [ ] No TypeScript errors
- [ ] No lint warnings
- [ ] Code formatted correctly
- [ ] No `console.log` statements left
- [ ] No `any` types introduced
- [ ] Server actions return `ActionResult<T>`
- [ ] Zod validation on external input
- [ ] `revalidatePath()` after mutations
- [ ] Error handling with proper logging

## PR Description Checklist

- [ ] Clear summary of changes
- [ ] Breaking changes documented
- [ ] Migration steps if needed
- [ ] Test plan described
- [ ] Screenshots for UI changes

## Quick Fix Commands

```bash
# Auto-fix lint issues
npm run lint -- --fix

# Format all files
npx prettier --write "**/*.{ts,tsx,js,jsx,json,md}"

# Run specific failing test
npx vitest run path/to/test.ts
```
