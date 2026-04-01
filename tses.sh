#!/usr/bin/env bash

BASE_DIR="$HOME/git"
if [ "${1:-}" = "--base" ]; then
  BASE_DIR="$2"
  shift 2
fi

action="${1:-}"
arg_name="${2:-}"

# -----------------------------------------------------------
# Helper: find top-level repos (fd + dedup), return full paths
# -----------------------------------------------------------
find_repos() {
  fd --hidden --no-ignore --type d '^\.git$' "$BASE_DIR" 2>/dev/null \
    | sed 's|/\.git/$||' \
    | sort \
    | awk '{
        skip = 0
        for (i = 1; i <= n; i++) {
          if (substr($0, 1, length(repos[i]) + 1) == repos[i] "/") {
            skip = 1; break
          }
        }
        if (!skip) { n++; repos[n] = $0; print $0 }
      }'
}

# Helper: list repos & show only last 2 path components
list_repos() {
  find_repos | awk -F/ '
    {
      if (NF >= 2) {
        print $(NF-1) "/" $NF
      } else {
        print $NF
      }
    }
  '
}

# Map displayed "parent/repo" back to full absolute path
resolve_path() {
  local display="$1"
  find_repos | grep "${display}$" | head -n 1
}

# -----------------------------------------------------------
# OPTION 1 — OPEN SESSION
# -----------------------------------------------------------
if [ "$action" = "open" ]; then

  # Direct open: tmux-sessionizer open myrepo
  if [ -n "$arg_name" ]; then
    REPO="$(resolve_path "$arg_name")"
    if [ -z "$REPO" ]; then
      echo "No repo matches: $arg_name"
      exit 1
    fi

  else
    # fzf picker
    SELECTED="$(list_repos | fzf --prompt='Repos > ')"
    [ -z "$SELECTED" ] && exit 0
    REPO="$(resolve_path "$SELECTED")"
  fi

  SESSION="$(basename "$REPO")"

  # Reattach if exists
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux switch-client -t "$SESSION" 2>/dev/null || tmux attach -t "$SESSION"
    exit 0
  fi

  # Create session
  if [ -n "$TMUX" ]; then
    tmux new-session -ds "$SESSION" -c "$REPO"
    tmux switch-client -t "$SESSION"
  else
    tmux new-session -s "$SESSION" -c "$REPO"
  fi

  exit 0
fi

# -----------------------------------------------------------
# OPTION 2 — KILL SESSION
# -----------------------------------------------------------
if [ "$action" = "kill" ]; then

  # Direct kill by name: tmux-sessionizer kill myrepo
  if [ -n "$arg_name" ]; then
    if tmux has-session -t "$arg_name" 2>/dev/null; then
      tmux kill-session -t "$arg_name"
      exit 0
    else
      echo "No tmux session matches: $arg_name"
      exit 1
    fi
  fi

  # No name → show list to kill
  SESSION="$(
    tmux ls 2>/dev/null \
      | cut -d: -f1 \
      | fzf --prompt='Kill session > '
  )"

  [ -z "$SESSION" ] && exit 0

  tmux kill-session -t "$SESSION"
  exit 0
fi

# -----------------------------------------------------------
# INVALID ARG
# -----------------------------------------------------------
echo "Usage: tses [--base DIR] {open [name] | kill [name]}"
exit 1
