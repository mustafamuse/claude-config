---
description: Run the autonomous PR pipeline — implement, typecheck, test, commit, push, open PR via /create-pr. Use only after explicit user confirmation that scope is finalized. Stops on any failure that recurs more than twice.
argument-hint: [optional context]
allowed-tools: Read, Edit, Write, Bash, Grep, Glob
model: sonnet
---

# /autopr — autonomous PR pipeline

Moved out of CLAUDE.md (was prose-only) into this on-demand skill so it doesn't take always-on context.

## When to invoke

Only after:
- User has confirmed the scope is final
- A plan exists (either via `/notes` or `.claude/plans/`)
- Verification commands are known

If any of those are missing, fall back to `/feature-gan` (which produces the plan first).

## Pipeline (no pause between steps unless a step fails > twice)

1. **Implement** — apply the change as scoped
2. **Static checks** — `bun run typecheck` (must be clean) then `bun run lint --fix`
3. **Tests** — `bun run test:run -- <pattern>` (only affected; widen scope only on failure)
4. **Commit** — descriptive imperative-mood message, no file lists
5. **Push** — `git push -u origin <branch>` (never force on main)
6. **PR** — invoke `/create-pr` (canonical PR format per user CLAUDE.md). Never use any other PR format.

## Failure escalation

| Step | First failure | Second failure | Third failure |
|------|--------------|----------------|--------------|
| typecheck | Fix and retry | Fix and retry | Stop, report errors |
| tests | Self-healing test loop (up to 3 cycles) | — | Stop, report what was tried |
| commit | Re-stage, retry | Stop, surface | — |
| push | Stop — likely SSH auth | — | — |
| PR | Stop, report | — | — |

Per user CLAUDE.md: **never retry a failed git push**.

## Hard stops

- TypeScript errors that touch files outside the scope of the change
- Test failures in unrelated test files (= you broke something off-task)
- Migration files in the diff without `migration-reviewer` agent invocation
- Auth/webhook changes without `security-reviewer` agent invocation
- Force-push to main attempted (also enforced by `block-dangerous.sh`)

## Gotchas

- `/create-pr` overrides all other PR formats (commit-push-pr plugin, project CLAUDE.md PR sections). Never write a different PR description format.
- The `.husky/_` deleted state shown in git status is unrelated to your branch; don't try to "fix" it.
- `bun run cleanup` runs format + lint --fix + typecheck together, but each step exits non-zero independently — use `bun run typecheck` separately if you want to fail fast.
