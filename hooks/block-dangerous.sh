#!/bin/bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Destructive file operations
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--force.*-r|-rf)\s'; then
  echo "Blocked: recursive force delete (rm -rf). Use targeted rm instead." >&2
  exit 2
fi

if echo "$COMMAND" | grep -qE 'sudo\s+rm\s'; then
  echo "Blocked: sudo rm. Remove files without sudo or ask the user." >&2
  exit 2
fi

# Database destructive operations
if echo "$COMMAND" | grep -qiE '(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+TABLE)'; then
  echo "Blocked: destructive database operation. Never drop or truncate tables." >&2
  exit 2
fi

if echo "$COMMAND" | grep -qE 'prisma\s+migrate\s+reset'; then
  echo "Blocked: prisma migrate reset. This destroys all data." >&2
  exit 2
fi

# Git destructive operations
# Block: git push --force (unsafe, can overwrite others' work)
# Allow: git push --force-with-lease (safe, fails if remote changed)
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)\b' && ! echo "$COMMAND" | grep -qE '\-\-force-with-lease'; then
  echo "Blocked: force push. Use --force-with-lease or ask the user." >&2
  exit 2
fi

# Block force push to main/master (even with --force-with-lease)
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force-with-lease' && echo "$COMMAND" | grep -qE '\s(main|master)\s*$'; then
  echo "Blocked: force push to main/master is never allowed." >&2
  exit 2
fi

# Block + refspec push to main/master (equivalent to --force)
if echo "$COMMAND" | grep -qE 'git\s+push\s+\S+\s+\+\S*main|git\s+push\s+\S+\s+\+\S*master'; then
  echo "Blocked: force push to main/master via + refspec." >&2
  exit 2
fi

if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard' \
  && ! echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard\s+(origin|upstream)/[a-zA-Z0-9._/-]+'; then
  echo "Blocked: git reset --hard. Allowed only when target is a remote tracking ref (origin/X or upstream/X). Use git stash or git restore otherwise." >&2
  exit 2
fi

if echo "$COMMAND" | grep -qE 'git\s+clean\s+.*-f'; then
  echo "Blocked: git clean -f. This permanently deletes untracked files." >&2
  exit 2
fi

if echo "$COMMAND" | grep -qE 'git\s+checkout\s+\.\s*$'; then
  echo "Blocked: git checkout . discards all changes. Use targeted restore." >&2
  exit 2
fi

# Credential exposure
if echo "$COMMAND" | grep -qE '(curl|wget).*(-u|--user)\s+[^$]'; then
  echo "Blocked: hardcoded credentials in curl/wget. Use environment variables." >&2
  exit 2
fi

exit 0
