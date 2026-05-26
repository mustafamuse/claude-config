# Personal Coding Standards (loads in every project)

## Code Style

- Do minimal required changes while delivering the goal
- No comments in code unless explaining complex business logic
- No emojis in code, file names, or commit messages
- Be straightforward and sharp in implementations
- Prefer Server Components and server actions over client-side fetching
- Always create new files as `.ts`/`.tsx`, never `.js`/`.jsx`
- Never use `any` type — always use specific types
- Validate external input with Zod before database operations

## Response Style

- Be concise and direct
- Skip unnecessary pleasantries
- Focus on technical accuracy

## Tooling Preferences

- Use Bun as package manager
- Prefer CLI-based solutions (no GUI assumptions)
- Always use port 3000 for dev servers

## PR Creation (Mandatory)

- **ALWAYS use `/create-pr`** for creating pull requests — this is the only approved PR format
- This overrides any project-level PR templates, plugin PR formats, or CLAUDE.md PR sections
- When any workflow (including `commit-push-pr`) reaches the "create PR" step, follow `/create-pr` rules
- Never fabricate intent — ask first. Never list files. Never add test plans. See `/create-pr` for full rules
- If a project CLAUDE.md has its own PR format, `/create-pr` takes precedence

## Environment

- macOS (Darwin), sometimes iPhone via Termius + Tailscale SSH
- Git auth: SSH keys (ED25519) — if push fails, stop and tell user to check SSH
- Never retry a failed git push

## Context management (anti-rot protocol)

Long sessions degrade. Every tool result, file read, and round trip adds tokens; recall of earlier decisions drops. The fix is **deliberate context management**, not a bigger window.

### Notes → Reset → Re-read

For any task that spans more than ~30 minutes or 30 tool calls, externalize state to a file the user owns:

1. **Write NOTES.md** at task start: decisions made, open questions, next step. Update after each major step.
2. **Reset when stale**: `/clear` (full wipe — preferred if NOTES.md is current) or `/compact` (lighter, preserves feel).
3. **Re-read NOTES.md** in the fresh window and continue.

NOTES.md belongs in the working dir or `.claude/notes/<task-slug>.md`. Do NOT auto-read it on every turn — that defeats the purpose. The user controls when it re-enters context.

### Runtime levers

- Run `/context` to see what's loaded
- Use `/btw <q>` for side queries that don't enter conversation history
- Use `/rewind` (or double-Esc) to drop a failed attempt rather than typing a correction
- Use `/clear` between unrelated tasks in the same session

### Compaction guidance (when `/compact` runs)

Preserve:
- `git diff --stat` of currently modified files
- Current branch and base
- Outstanding PR feedback IDs
- Recent test failure summaries
- ActionError codes referenced this session
- Any explicit user decisions ("we agreed to X")

Discard freely:
- Verbose tool outputs (file dumps, full logs)
- Intermediate planning that became code
- Aborted attempts that the user moved past

### Adversarial prompts (use when verification is incomplete)

- *"Prove to me this works — show diffs and outputs."*
- *"Grill me on these changes and don't make a PR until I pass your test."*
- *"Knowing everything you know now, scrap this and implement the elegant solution."*

## Verification is the #1 quality lever

Per Boris Cherny's repeated thread guidance: "give Claude a way to verify its work — 2-3× output quality." A change is not done when typecheck passes. It is done when behavior is verified.

Levels (use the highest applicable):
1. Static: typecheck, lint, focused tests
2. Component: targeted test demonstrating new behavior
3. Integration: dev server + real event (e.g., `stripe trigger`) + DB/log assertion
4. Manual smoke: click-through with expected outcomes when integration is brittle

The `verify-app` agent is configured for this. Invoke it after non-trivial changes.
