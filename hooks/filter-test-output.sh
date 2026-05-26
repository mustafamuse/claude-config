#!/bin/bash
# PreToolUse(Bash) hook: rewrite verbose test/lint commands to pipe through
# a failure-only filter. Per Anthropic /costs doc: reduces 10k tokens to 100s
# when tests pass cleanly. Only triggers on known commands.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Detect known noisy commands
should_filter=false
case "$COMMAND" in
  *"bun run test"*|*"bun test"*|*"npm test"*|*"npm run test"*|*"vitest"*|*"bunx vitest"*)
    should_filter=true
    ;;
  *"bun run lint"*|*"npm run lint"*|*"eslint"*)
    should_filter=true
    ;;
  *"bun run typecheck"*|*"npm run typecheck"*|*"tsc --noEmit"*|*"bunx tsc"*)
    should_filter=true
    ;;
esac

if [ "$should_filter" != "true" ]; then
  exit 0
fi

# Skip if user already piped/redirected
if echo "$COMMAND" | grep -qE '[\|>]|2>&1'; then
  exit 0
fi

# Wrap command to show only FAIL/ERROR lines + 5 lines of context, plus a tail
# of the original (so we keep the summary). If output is small, pass through.
FILTERED="set -o pipefail; OUTPUT=\$($COMMAND 2>&1); EXIT=\$?; LINES=\$(echo \"\$OUTPUT\" | wc -l | tr -d ' '); if [ \"\$LINES\" -lt 80 ] || [ \"\$EXIT\" -eq 0 ]; then echo \"\$OUTPUT\" | tail -40; else echo \"--- filtered (FAIL/ERROR + context) ---\"; echo \"\$OUTPUT\" | grep -E -B1 -A5 '(FAIL|✗|Error|error TS[0-9]+|ERR_|✘)' | head -100; echo \"--- summary (last 20 lines) ---\"; echo \"\$OUTPUT\" | tail -20; fi; exit \$EXIT"

jq -n --arg cmd "$FILTERED" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "updatedInput": { "command": $cmd }
  }
}'
