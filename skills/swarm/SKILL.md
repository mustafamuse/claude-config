---
description: Fan out a refactor or migration across 3+ files using parallel subagents. Each agent works on one file or module and reports back. Use for mechanical changes (renames, pattern migrations, bulk type updates) where files are independent.
argument-hint: <description of the change to fan out>
allowed-tools: Task, Read, Grep, Glob, Bash
model: sonnet
---

# /swarm — parallel agent fan-out

Moved out of CLAUDE.md (was "Parallel Agent Swarm for Refactors" prose) into this on-demand skill.

## When to use

Files must be **independent** — no shared imports they all modify, no test files all asserting on the same fixture. If files share state, use `/feature-gan` instead (sequential by design).

Good fits:
- Rename a function across 20 callsites
- Migrate all `app/admin/*/actions.ts` from one safe-action client variant to another
- Add `'use server'` directive to files missing it
- Convert all relative imports under `lib/` to `@/lib/` aliases

Bad fits:
- Add a feature that touches multiple layers (use `/feature-gan`)
- Migrate a schema that requires inter-file coordination
- Rename a type used in 50 files with subtle generic interactions (start with one, then `/swarm` the rest)

## Process

1. **Decompose**: list the files. If > 20, batch into groups of 5-10.
2. **Spawn**: launch one `worktree-worker` agent per file (or per group), via parallel Task calls in a single message
3. **Each agent**:
   - Applies the pattern from the brief
   - Runs `bun run typecheck` on its file's scope
   - Reports back with diff stat + status (pass/fail + reason)
4. **Aggregate**: collect all reports, present a table, ask user which to commit
5. **Commit**: in one commit (or one-per-logical-group) on the parent branch

## Output format

```
## /swarm report: <change description>

| File | Agent | Status | Lines changed | Notes |
|------|-------|--------|---------------|-------|
| app/admin/mahad/students/actions.ts | worktree-worker#1 | ✓ | +5 -2 | |
| app/admin/mahad/cohorts/actions.ts | worktree-worker#2 | ✓ | +5 -2 | |
| app/admin/dugsi/teachers/actions.ts | worktree-worker#3 | ✗ | — | already migrated; skipped |
| app/admin/dugsi/family/actions.ts | worktree-worker#4 | ✓ | +5 -2 | |

**Aggregate**: 3 files changed, +15 -6 lines. Suggested commit: "migrate admin actions to adminActionClient"
**Skipped**: 1 (already migrated)
**Failed**: 0
```

## Gotchas

- Sub-agents do **not** share context — each one reads the brief independently. Make the brief specific enough to be standalone
- `worktree-worker` agents work in isolated worktrees by default; their commits land on isolated branches. The parent must merge or aggregate them
- TypeScript projects: each agent runs `tsc --noEmit` scoped to its file via `--incremental false`. A change passing in isolation may fail at the project level if it touches a shared type — always run `bun run typecheck` at the parent level after aggregation
- Vitest runs in the parent — sub-agents skip tests to avoid contention; parent re-runs tests once after aggregation
- Cap parallelism at 5 concurrent sub-agents — Anthropic's multi-agent research showed performance plateaus past 5 and token cost grows linearly

## Cost note

Per Anthropic's June 2025 multi-agent research post: agent calls cost ~4× a chat, multi-agent ~15×. For 20 trivial renames, a swarm of 5 agents costs ~75× a single chat call but completes in ~1/5 the wall time. Use deliberately.
