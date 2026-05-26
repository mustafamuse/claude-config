# Claude Code shell helpers — source from ~/.zshrc:
#   [ -f ~/dev/claude-config/zsh/claude-aliases.zsh ] && source ~/dev/claude-config/zsh/claude-aliases.zsh

# Worktree aliases (Boris Cherny pattern)
# Each opens an isolated git worktree under <repo>/.claude/worktrees/<name>
# and launches claude inside it.
za() { _claude_worktree "$1"; }
zb() { _claude_worktree "$1"; }
zc() { _claude_worktree "$1"; }

_claude_worktree() {
  local name="$1"
  if [ -z "$name" ]; then
    echo "usage: za <name> | zb <name> | zc <name>" >&2
    return 1
  fi
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "not in a git repo" >&2; return 1; }
  local wt="$repo_root/.claude/worktrees/$name"
  if [ ! -d "$wt" ]; then
    git -C "$repo_root" worktree add "$wt" -b "$name" || return 1
  fi
  cd "$wt" && claude
}

zl() {
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  git -C "$repo_root" worktree list
}

zd() {
  local name="$1"
  if [ -z "$name" ]; then
    echo "usage: zd <worktree-name>" >&2
    return 1
  fi
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  git -C "$repo_root" worktree remove "$repo_root/.claude/worktrees/$name"
}
