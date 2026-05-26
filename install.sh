#!/usr/bin/env bash
# Install this Claude Code config onto a fresh machine.
#
# Strategy: for each managed item under ~/.claude/, back up any existing file
# to <path>.preinstall-<timestamp>, then symlink ~/.claude/<x> -> $REPO/<x>.
#
# Idempotent: re-running detects existing correct symlinks and skips.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# Items to manage. Format: <repo_path>:<claude_subpath>
ITEMS=(
  "CLAUDE.md:CLAUDE.md"
  "settings.json:settings.json"
  "agents:agents"
  "hooks:hooks"
  "skills:skills"
  "output-styles:output-styles"
  "commands:commands"
)

mkdir -p "$CLAUDE_DIR"

link_one() {
  local src="$1"
  local dst="$2"
  if [ -L "$dst" ]; then
    local current
    current="$(readlink "$dst")"
    if [ "$current" = "$src" ]; then
      echo "  ok      $dst -> $src"
      return 0
    fi
    echo "  relink  $dst (was -> $current)"
    rm "$dst"
  elif [ -e "$dst" ]; then
    local backup="${dst}.preinstall-${TIMESTAMP}"
    echo "  backup  $dst -> $backup"
    mv "$dst" "$backup"
  fi
  ln -s "$src" "$dst"
  echo "  link    $dst -> $src"
}

echo "Installing from: $REPO_DIR"
echo "Target:          $CLAUDE_DIR"
echo

for entry in "${ITEMS[@]}"; do
  repo_path="${entry%%:*}"
  claude_path="${entry##*:}"
  src="${REPO_DIR}/${repo_path}"
  dst="${CLAUDE_DIR}/${claude_path}"
  if [ ! -e "$src" ]; then
    echo "  skip    $repo_path (not in repo)"
    continue
  fi
  link_one "$src" "$dst"
done

echo
echo "Done. Preinstall backups (if any) are at ${CLAUDE_DIR}/*.preinstall-${TIMESTAMP}"
echo
echo "Next:"
echo "  1. Add to ~/.zshrc:"
echo "       [ -f ${REPO_DIR}/zsh/claude-aliases.zsh ] && source ${REPO_DIR}/zsh/claude-aliases.zsh"
echo "  2. source ~/.zshrc"
echo "  3. Restart Claude Code to pick up settings."
