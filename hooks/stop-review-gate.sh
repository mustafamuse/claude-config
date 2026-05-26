#!/bin/bash
# Stop hook gate: cheap bash check before deciding if a review is needed.
# Replaces the previous "spawn Opus agent on every Stop" pattern which burned
# tokens on no-op stops. Per Boris Cherny: agents are explicitly invoked when
# you want them, not auto-spawned.

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Anti-loop: if we're already inside a stop-hook spawned context, exit clean
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  echo '{"ok": true}'
  exit 0
fi

# Only gate inside a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"ok": true}'
  exit 0
fi

# Count uncommitted changes
STAT=$(git diff --stat 2>/dev/null | tail -1)
FILES=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
LINES=$(echo "$STAT" | grep -oE '[0-9]+ insertion|[0-9]+ deletion' | grep -oE '[0-9]+' | awk '{s+=$1} END {print s+0}')

# No diff → clean stop
if [ "$FILES" = "0" ]; then
  echo '{"ok": true}'
  exit 0
fi

# Trivial diff → clean stop (don't waste a review pass)
if [ "$FILES" -lt 3 ] && [ "$LINES" -lt 30 ]; then
  echo '{"ok": true}'
  exit 0
fi

# Non-trivial diff: allow stop but nudge user toward explicit review
cat <<EOF
{"ok": true, "systemMessage": "Diff is non-trivial ($FILES files, ~$LINES lines changed). Consider running /code-review max --comment or invoking the staff-reviewer / security-reviewer / verify-app agent before committing."}
EOF
exit 0
