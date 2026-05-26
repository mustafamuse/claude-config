#!/bin/bash
# WorktreeCreate hook: symlinks .env.local from main repo into new worktree
# so the dev server and Stripe listener work without manual setup.

INPUT=$(cat)
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.worktree_path // .tool_input.path // empty')

if [ -z "$WORKTREE_PATH" ] || [ ! -d "$WORKTREE_PATH" ]; then
  exit 0
fi

# Derive main repo path from `git worktree list` (first entry is the main repo)
cd "$WORKTREE_PATH" 2>/dev/null || exit 0
MAIN_REPO=$(git worktree list --porcelain 2>/dev/null | grep '^worktree ' | head -1 | sed 's|^worktree ||')

if [ -z "$MAIN_REPO" ] || [ "$MAIN_REPO" = "$WORKTREE_PATH" ]; then
  exit 0
fi

# Symlink env files if they exist in main repo and not in worktree
for envfile in .env .env.local .env.development; do
  if [ -f "$MAIN_REPO/$envfile" ] && [ ! -e "$WORKTREE_PATH/$envfile" ]; then
    ln -s "$MAIN_REPO/$envfile" "$WORKTREE_PATH/$envfile"
  fi
done

# Optionally symlink node_modules if present (much faster than re-install)
if [ -d "$MAIN_REPO/node_modules" ] && [ ! -e "$WORKTREE_PATH/node_modules" ]; then
  ln -s "$MAIN_REPO/node_modules" "$WORKTREE_PATH/node_modules"
fi

exit 0
