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
# GitHub fetch helpers (used by pull action)
# -----------------------------------------------------------
fetch_my_repos() {
  gh repo list "$GH_USER" --json nameWithOwner --limit 100 -q '.[].nameWithOwner'
}

# shellcheck disable=SC2329
fetch_starred_repos() {
  gh api /user/starred --paginate --jq '.[].full_name'
}

# shellcheck disable=SC2329
fetch_org_repos() {
  local org
  while IFS= read -r org; do
    [ -z "$org" ] && continue
    gh repo list "$org" --json nameWithOwner --limit 100 -q '.[].nameWithOwner'
  done <<< "$GH_ORGS"
}

# shellcheck disable=SC2329
fetch_recommended_repos() {
  gh api "/users/$GH_USER/received_events" --jq '[.[] | select(.type=="WatchEvent" or .type=="ForkEvent") | .repo.name] | unique | .[]'
}

# Search GitHub repos by query (called via tses_search_or_noop)
# shellcheck disable=SC2329
fetch_search_repos() {
  local query="${1:-}"
  [ -z "$query" ] && return 0
  gh api "/search/repositories?q=$(printf '%s' "$query" | jq -sRr @uri)&per_page=50" --jq '.items[].full_name'
}

# Called on every fzf change event — if in search mode, query API; otherwise re-cat cached browse data
# shellcheck disable=SC2329
tses_search_or_noop() {
  local view
  view="$(cat "$TSES_VIEW_FILE" 2>/dev/null)" || return 0
  if [ "$view" = "Search GitHub" ]; then
    fetch_search_repos "$1"
  else
    cat "$TSES_BROWSE_CACHE" 2>/dev/null || true
  fi
}

# Pick a view (called via fzf execute — needs terminal for nested fzf)
# Only writes view name to file; the actual fetch happens in reload
# shellcheck disable=SC2329
tses_pick_view() {
  printf 'My repos\nStarred\nOrganizations\nRecommended\nSearch GitHub' \
    | fzf --prompt='View > ' > "$TSES_VIEW_FILE" || true
}

# Fetch repos for the selected view (called via fzf reload — fzf stays visible)
# Browse views cache their output so tses_search_or_noop can re-cat it on change events
# shellcheck disable=SC2329
tses_fetch_view() {
  local view
  view="$(cat "$TSES_VIEW_FILE" 2>/dev/null)" || return 0
  if [ "$view" = "Search GitHub" ]; then
    # Return empty — user types to search; change event handles API calls
    return 0
  fi
  # Browse views: fetch + cache
  local results
  case "$view" in
    'My repos')       results="$(fetch_my_repos)";;
    'Starred')        results="$(fetch_starred_repos)";;
    'Organizations')  results="$(fetch_org_repos)";;
    'Recommended')    results="$(fetch_recommended_repos)";;
  esac
  printf '%s' "${results:-}" > "$TSES_BROWSE_CACHE"
  printf '%s\n' "${results:-}"
}

# Return header text for the selected view (called via fzf transform-header)
# shellcheck disable=SC2329
tses_header_view() {
  local view
  view="$(cat "$TSES_VIEW_FILE" 2>/dev/null)" || return 0
  case "$view" in
    'My repos')       echo "View: My repos | ctrl-/ to switch";;
    'Starred')        echo "View: Starred | ctrl-/ to switch";;
    'Organizations')  echo "View: Organizations | ctrl-/ to switch";;
    'Recommended')    echo "View: Recommended | ctrl-/ to switch";;
    'Search GitHub')  echo "View: Search GitHub | Type to search | ctrl-/ to switch";;
    *)                echo "ctrl-/ to switch view";;
  esac
}

# Pick a destination parent directory under BASE_DIR
# shellcheck disable=SC2329
pick_destination() {
  local dirs
  dirs="$(find_repos | xargs -I{} dirname {} | sort -u | sed "s|^${BASE_DIR}/||")"
  local selection
  selection="$(printf '+ New directory\n%s' "$dirs" | fzf --prompt='Destination > ' --header='Pick parent directory for clone')"
  [ -z "$selection" ] && return 1

  if [ "$selection" = "+ New directory" ]; then
    local newdir
    read -rp "New directory name (relative to $BASE_DIR): " newdir
    [ -z "$newdir" ] && return 1
    mkdir -p "$BASE_DIR/$newdir"
    echo "$BASE_DIR/$newdir"
  else
    echo "$BASE_DIR/$selection"
  fi
}

# Called via fzf become — handles already-cloned check + destination picker
# Outputs "EXISTING:<path>" or "CLONE:<repo>:<dest>" for the caller to parse
# shellcheck disable=SC2329
tses_pull_select() {
  local selected="$1"
  local repo_name="${selected##*/}"

  # Check if already cloned
  local existing
  existing="$(find_repos | grep "/${repo_name}$" | head -n 1)" || true
  if [ -n "$existing" ]; then
    echo "EXISTING:${existing}"
    return
  fi

  # Destination picker (seamless fzf-to-fzf via become)
  local dest
  dest="$(pick_destination)" || return 1
  echo "CLONE:${selected}:${dest}"
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
  if [ -n "${TMUX:-}" ]; then
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
# OPTION 3 — PULL (browse & clone GitHub repos)
# -----------------------------------------------------------
if [ "$action" = "pull" ]; then

  # Auth check
  if ! gh auth status &>/dev/null; then
    echo "GitHub CLI not authenticated. Run: gh auth login"
    exit 1
  fi

  # Prefetch user info
  GH_USER="$(gh api /user --jq '.login')"
  GH_ORGS="$(gh api /user/orgs --jq '.[].login')"
  export GH_USER GH_ORGS BASE_DIR

  # fzf runs subcommands via $SHELL — must be bash for export -f to work
  SHELL="$(command -v bash)"
  export SHELL

  # Export helpers so fzf subshells can call them
  export -f find_repos fetch_my_repos fetch_starred_repos fetch_org_repos fetch_recommended_repos
  export -f fetch_search_repos tses_search_or_noop
  export -f tses_pick_view tses_fetch_view tses_header_view
  export -f pick_destination tses_pull_select

  # Temp files (view selection + browse cache for search/noop switching)
  TSES_VIEW_FILE="/tmp/tses-view-$$"
  TSES_BROWSE_CACHE="/tmp/tses-browse-$$"
  export TSES_VIEW_FILE TSES_BROWSE_CACHE
  trap 'rm -f "$TSES_VIEW_FILE" "$TSES_BROWSE_CACHE"' EXIT

  # Phase 1-3: repo browser → destination picker (seamless fzf-to-fzf via become)
  # become: replaces main fzf with tses_pull_select (which runs destination fzf)
  # Cache initial browse results so tses_search_or_noop can re-cat them
  echo "My repos" > "$TSES_VIEW_FILE"
  INITIAL_REPOS="$(fetch_my_repos)"
  printf '%s' "$INITIAL_REPOS" > "$TSES_BROWSE_CACHE"
  RESULT="$(printf '%s\n' "$INITIAL_REPOS" | fzf \
    --prompt='Repos > ' \
    --header='View: My repos | ctrl-/ to switch' \
    --delay 300 \
    --bind "ctrl-/:execute(tses_pick_view)+reload(tses_fetch_view)+transform-header(tses_header_view)" \
    --bind "change:reload(tses_search_or_noop {q})" \
    --bind "enter:become(tses_pull_select {})"
  )" || true
  [ -z "${RESULT:-}" ] && exit 0

  # Phase 4: clone + open (terminal visible for progress output)
  if [[ "$RESULT" == EXISTING:* ]]; then
    existing="${RESULT#EXISTING:}"
    echo "Repo already cloned at: $existing"
    read -rp "Open tmux session? [Y/n] " open_confirm
    if [ "${open_confirm:-Y}" != "n" ] && [ "${open_confirm:-Y}" != "N" ]; then
      SESSION="$(basename "$existing")"
      if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux switch-client -t "$SESSION" 2>/dev/null || tmux attach -t "$SESSION"
      elif [ -n "${TMUX:-}" ]; then
        tmux new-session -ds "$SESSION" -c "$existing"
        tmux switch-client -t "$SESSION"
      else
        tmux new-session -s "$SESSION" -c "$existing"
      fi
    fi
  elif [[ "$RESULT" == CLONE:* ]]; then
    rest="${RESULT#CLONE:}"
    SELECTED="${rest%%:*}"
    DEST="${rest#*:}"
    repo_name="${SELECTED##*/}"

    echo "Cloning $SELECTED into $DEST/$repo_name..."
    gh repo clone "$SELECTED" "$DEST/$repo_name"

    read -rp "Open tmux session? [Y/n] " open_confirm
    if [ "${open_confirm:-Y}" != "n" ] && [ "${open_confirm:-Y}" != "N" ]; then
      SESSION="$repo_name"
      if [ -n "${TMUX:-}" ]; then
        tmux new-session -ds "$SESSION" -c "$DEST/$repo_name"
        tmux switch-client -t "$SESSION"
      else
        tmux new-session -s "$SESSION" -c "$DEST/$repo_name"
      fi
    fi
  fi

  exit 0
fi

# -----------------------------------------------------------
# INVALID ARG
# -----------------------------------------------------------
echo "Usage: tses [--base DIR] {open [name] | kill [name] | pull}"
exit 1
