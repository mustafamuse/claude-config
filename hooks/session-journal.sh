#!/bin/bash
# SessionEnd hook: write a session journal entry to a per-project review queue
# so durable learnings can be promoted into MEMORY.md by the user.
#
# Spawning a subagent on every SessionEnd to scan the transcript is expensive.
# Instead, this writes a structured stub the user can fill in or hand to the
# next session for processing with the /notes skill.

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"')

# Skip if not in a project (no git repo)
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel)
JOURNAL_DIR="${PROJECT_ROOT}/.claude/notes/session-journal"
mkdir -p "$JOURNAL_DIR"

DATE=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
DATE_HUMAN=$(date -u +"%Y-%m-%d %H:%M UTC")
BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "(detached)")
DIFF_STAT=$(git diff --stat 2>/dev/null | tail -10)
LAST_COMMITS=$(git log --oneline -5 2>/dev/null)

JOURNAL_FILE="${JOURNAL_DIR}/${DATE}.md"

cat > "$JOURNAL_FILE" <<EOF
# Session Journal — ${DATE_HUMAN}

_Session: ${SESSION_ID:-unknown}_
_End reason: ${REASON}_
_Branch: ${BRANCH}_

## Uncommitted state at end

\`\`\`
${DIFF_STAT:-(no diff)}
\`\`\`

## Recent commits

\`\`\`
${LAST_COMMITS}
\`\`\`

## Learnings to promote to MEMORY.md

<!--
List durable facts worth saving here. The next session can read this file
and propose MEMORY.md additions. Delete this comment block once filled.

Categories:
- user — preferences, working style
- feedback — correction patterns, dismissed bot suggestions
- project — ongoing goals, constraints, gotchas you noticed
- reference — useful URLs, dashboard links discovered
-->

## TODOs noticed but not addressed

<!-- E.g., "lib/services/shared/billing.ts has duplicated rounding logic that should be extracted" -->

EOF

# Trim the journal directory to last 30 entries (keep recent, drop ancient)
ls -1t "$JOURNAL_DIR"/*.md 2>/dev/null | tail -n +31 | xargs -I{} rm -f {} 2>/dev/null

exit 0
