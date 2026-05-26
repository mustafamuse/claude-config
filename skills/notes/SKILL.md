---
description: Bootstrap or refresh a NOTES.md file for the current task. Use at task start for any work spanning >30 min or >30 tool calls, after /clear or /compact to re-orient, or any time the session is feeling stale. Implements the anti-context-rot protocol from ~/.claude/CLAUDE.md.
argument-hint: [task-slug-or-summary]
allowed-tools: Read, Write, Edit, Bash
---

# /notes — task state externalization

The single most effective habit for long-running tasks: externalize state to a file that survives `/clear` and `/compact`.

## When the user invokes `/notes`

### No NOTES.md exists yet → create it

Location: prefer `.claude/notes/<task-slug>.md` (gitignored is fine), fall back to `./NOTES.md`. If `$ARGUMENTS` is given, use it as the slug.

Bootstrap content:

```markdown
# NOTES — <task summary>

_Started: <UTC timestamp>_
_Branch: <current branch>_

## Goal

<one-sentence statement of what we're trying to accomplish>

## Decisions

<empty — fill as we make them>

## Open questions

<empty — fill as they come up>

## Next step

<what we'll do first>

## Done

<empty — append as we complete units>
```

### NOTES.md exists → re-read and re-orient

1. Read the file
2. Show the user: goal, last decision, next step (3 lines max)
3. Confirm we're picking up from "next step"

### NOTES.md exists but is stale → refresh

If the user says "the notes are stale" or the goal has shifted, update the goal + next-step sections without losing the decisions log.

## Update protocol

After each major step:
- Append the unit to `## Done`
- If a non-obvious decision was made, log it under `## Decisions` with one-line "why"
- Update `## Next step`

Keep the whole file under ~150 lines. If it grows past that, summarize the `## Done` section and move detail to a `notes-archive-<date>.md`.

## When NOT to write notes

- Single-file edits
- Pure bugfixes with a clear repro
- Refactors that complete in one tool sequence

NOTES.md is overhead. Use it when the task is long enough that the overhead beats context rot.

## Gotchas

- **Do not auto-read NOTES.md every turn** — that defeats the purpose (the whole point is to keep it OUT of the live context window until you reset). The user controls when it re-enters.
- The file should be **gitignored** unless the team wants persistent task journals. Default to gitignore.
- Don't write decisions you're not sure about — log them as open questions instead. Decisions are commitments.
- After a `/clear`, the first thing the user does is invoke `/notes` again to re-read.

## The full anti-rot loop

```
1. Write notes
2. Work
3. (Update notes)
4. (Keep working)
5. Context feels stale OR you finish a logical unit
6. /clear (or /compact)
7. /notes  ← re-reads the file and re-orients
8. Continue
```
