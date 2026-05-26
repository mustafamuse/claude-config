#!/bin/bash
# UserPromptSubmit hook: inject current git context so Claude doesn't have to ask.
# Per Boris Cherny's pattern of pre-computing git status in slash commands.

INPUT=$(cat)

# Only act inside a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo '{"continue": true}'
  exit 0
fi

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "(detached)")
BASE_BRANCH=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || echo "main")

# Stat against base (capped to keep output small)
DIFF_STAT=$(git diff --stat "origin/${BASE_BRANCH}..HEAD" 2>/dev/null | tail -10)
UNCOMMITTED=$(git diff --stat 2>/dev/null | tail -1)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | head -5)

# Compose system-reminder content (kept short to minimize token cost per prompt)
CONTEXT="<git-context>
branch: ${BRANCH} (base: ${BASE_BRANCH})
$( [ -n "$DIFF_STAT" ] && echo "committed-vs-base:
${DIFF_STAT}" )
$( [ -n "$UNCOMMITTED" ] && [ "$UNCOMMITTED" != "" ] && echo "uncommitted: ${UNCOMMITTED}" )
$( [ -n "$UNTRACKED" ] && echo "untracked (top 5):
${UNTRACKED}" )
</git-context>"

# Emit additional context for the model
jq -n --arg ctx "$CONTEXT" '{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": $ctx
  }
}'
