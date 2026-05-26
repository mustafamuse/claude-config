---
description: Babysit open PRs — address bot review comments, rebase on main, and shepherd toward merge. Use with /loop 5m /babysit for continuous handling. Per Boris Cherny's daily workflow.
argument-hint: [pr-number-or-branch]
allowed-tools: Read, Grep, Glob, Bash, Edit
model: sonnet
---

Babysit one PR (or detect the current branch's PR) and move it forward without human intervention where safe.

## Operating loop

1. **Identify the PR**
   - If `$ARGUMENTS` is provided, treat it as a PR number or branch
   - Otherwise: `gh pr view --json number,state,headRefName,reviewDecision,statusCheckRollup`
   - If no PR exists for current branch, exit cleanly with "no PR found"

2. **Read state**
   - `gh pr checks` — note any failing CI
   - `gh pr view --comments --json reviews,comments` — read all bot + human comments
   - `git log --oneline origin/main..HEAD` — what's in flight

3. **Decide and act per pattern**
   - **Failing CI (typecheck/lint/test)**: run locally, fix, push
   - **Mergeable but behind main**: `git fetch origin && git rebase origin/main && git push --force-with-lease`
   - **Bot review (claude[bot], CodeRabbit, etc.) with actionable comments**: see policy below
   - **Human review requesting changes**: do NOT auto-address; report and stop
   - **All green + approved**: report ready, do **not** auto-merge (user policy)

4. **Loop back to step 2** at most 3 times per invocation

## Bot-comment policy (matches `feedback_address_feedback_loop.md` memory)

Bot comments that should be **dismissed without action**:
- Add JSDoc to internal functions
- Don't over-fetch (when query is intentional)
- Suggest extracting a hook when readability is fine
- Cosmetic style nits Prettier already passed

Bot comments that **should be addressed**:
- Actual bug catches (off-by-one, null handling, missing await)
- Security findings with reproducible exploit path
- Type-safety violations the typechecker missed (e.g., narrowing)
- Performance findings on hot paths

When in doubt: leave the comment unaddressed and report it in the summary.

## Output format

```
## Babysit run: PR #<n> on <branch>

**Actions taken**:
- Rebased on origin/main (clean)
- Fixed 2 failing tests in app/admin/mahad/_lib/student-form-utils.test.ts
- Dismissed 1 bot JSDoc nit (per policy)

**Remaining**:
- 1 human review comment pending — NOT auto-addressed:
  > "Can you split this into two PRs?"
- Awaiting CI rerun

**Next**: `/loop 5m /babysit` will pick this up again
```

## Hard refusals

- Never auto-merge
- Never force-push to main
- Never amend a commit that's been reviewed (creates noise; add new commit instead)
- Never auto-rebase past your own commits (could lose work)

## Gotchas

- `gh pr checks` sometimes lags; if status is "pending" but workflow finished, wait 10s and re-check
- `--force-with-lease` is safe for rebase-push; **never** use `--force` (block-dangerous.sh enforces this)
- Squash-merge is the team default — keep commits clean but don't worry about intermediate messy commits, they collapse on merge
- Project uses `commit-push-pr` plugin format for PRs but `/create-pr` is the canonical PR description format per user CLAUDE.md
