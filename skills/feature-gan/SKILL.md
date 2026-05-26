---
description: Build a feature end-to-end using the GAN-style three-agent harness (Planner / Generator / Evaluator). Use for non-trivial features where verification matters more than speed. Per Anthropic's "harness design for long-running app dev" (March 2026).
argument-hint: <feature description>
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
model: opus
---

# /feature-gan — Planner / Generator / Evaluator

A three-agent harness where Generator and Evaluator critique each other until a verifiable goal is met. Sonnet 4.5+ tends to do "context anxiety" in long sessions — this skill resets context between stages to stay sharp.

## When to use

Use for changes that meet **all** of:
- ≥ 30 minutes of work
- Touches 3+ files or 1 high-risk path
- Has a verifiable goal (typecheck + tests + behavior)

Skip for: bugfixes with a clear repro, refactors with a single intent, doc edits.

## Three stages

### Stage 1 — Planner (Opus, plan mode)

Goal: produce a `.claude/plans/<date>-<slug>.md` artifact that contains:
- Goal (1 sentence)
- Acceptance criteria (verifiable bullets, e.g., "test X passes", "behavior Y returns Z")
- Files to touch + 1-line per-file purpose
- High-risk paths invoked (link to `migration-reviewer` / `security-reviewer` if needed)
- Verification commands (the exact bash to run)

**Process**: Use AskUserQuestion via the `interview` skill if requirements are unclear. Aim for 5-10 questions max. Read existing code via `code-explorer` agent (read-only Haiku, fork context).

Output: plan file path. Stop here — do **not** start implementing.

### Stage 2 — Generator (Sonnet, default mode)

Read the plan from Stage 1 (and **only** the plan + the files it references). Implement, file by file, in the order listed in the plan.

**Generator rules**:
- Stay strictly within the file list. Do not refactor adjacent code.
- Run the verification commands from the plan after each file's edit, not just at end.
- If verification fails, log the failure in the plan's "Failures" section but keep going.
- Stop when all files in the plan are touched.

Output: branch with all changes committed (one commit per logical unit).

### Stage 3 — Evaluator (Sonnet, with Playwright MCP + verify-app agent)

Read the plan's acceptance criteria. Verify **each** one. Run:
- `bun run typecheck` (full repo)
- Affected tests via Vitest
- For UI: navigate via Playwright, screenshot, compare against expectation
- For webhooks: `stripe trigger <event>` + DB assertion
- For migrations: `migration-reviewer` agent

For each acceptance criterion, output: PASS / FAIL with evidence (output snippet, screenshot path, DB row count).

If any FAIL, hand back to Generator with the specific failure. Generator iterates. Max 3 cycles before halting with a report.

## Output format

```
## Feature: <name>

**Plan**: .claude/plans/<date>-<slug>.md
**Branch**: <branch-name>

### Stage 1 (Planner): COMPLETE
- Plan written: 7 acceptance criteria
- High-risk paths invoked: prisma/schema.prisma → migration-reviewer

### Stage 2 (Generator): COMPLETE
- 5 files touched, 3 commits
- Per-file verification: 4/5 passed in-stage; 1 failure caught at file 4 (handled by Stage 3)

### Stage 3 (Evaluator): PASS
- Acceptance criterion 1 (typecheck): ✓
- Acceptance criterion 2 (test X): ✓ (5 passed, 0 failed)
- Acceptance criterion 3 (behavior Y → Z): ✓ (DB row count went from 0 to 5)
- Cycles: 2 (one Generator iteration after first Evaluator FAIL)

### Verdict: SHIP
```

## Gotchas

- **Context resets between stages are intentional** — re-read the plan, don't trust memory. Per Anthropic's harness post: context resets beat compaction for Sonnet 4.5+ "context anxiety"
- **Plans must be verifiable**, not aspirational. "Make the form better" is not a verifiable criterion. "Form accepts DOB in MM/DD/YYYY format and rejects MM-DD-YYYY" is
- **Never let Generator rewrite the plan** — if the plan needs changes, Planner reopens it
- **3-cycle limit on Generator/Evaluator loop** — if not converging, the problem is the plan; reopen Stage 1
- **`stripe trigger` in Stage 3** requires the local listener (`bun run stripe:listen`). Generator must not run the listener — Evaluator manages it

## Why this works

From Anthropic's harness design post (March 2026): single-agent loops fall into local minima — Claude rationalizes away failures and stops too early. Splitting Planner / Generator / Evaluator forces independent verification. The 90.2% accuracy uplift from multi-agent research carries over to coding when stages are explicit.

Per Boris Cherny: "Give Claude a way to verify its work — 2-3× output quality." This skill makes that verification structural.
