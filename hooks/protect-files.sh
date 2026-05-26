#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Block editing env files with secrets
if [[ "$FILE_PATH" =~ \.env($|\.local|\.production) ]] && [[ ! "$FILE_PATH" =~ \.example$ ]]; then
  echo "Blocked: cannot edit $FILE_PATH (contains secrets). Edit .env.example instead." >&2
  exit 2
fi

# Block editing lock files
if [[ "$FILE_PATH" =~ (package-lock\.json|bun\.lockb|yarn\.lock|pnpm-lock\.yaml)$ ]]; then
  echo "Blocked: cannot edit lock file directly. Use package manager commands." >&2
  exit 2
fi

# Block editing git internals
if [[ "$FILE_PATH" =~ \.git/ ]]; then
  echo "Blocked: cannot edit git internals directly." >&2
  exit 2
fi

exit 0
