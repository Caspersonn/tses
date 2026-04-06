## Context

`tses pull` has 4 pre-fetched views (my repos, starred, orgs, recommended). All views load data once, then fzf filters locally. There's no way to search GitHub's full index of public/private repos. The ctrl-/ menu pattern and helper function architecture are already in place.

## Goals / Non-Goals

**Goals**:
- Add a "Search GitHub" view that queries GitHub's search API as the user types
- Cap results at 50 per query (relevance-sorted — if top 50 don't match, refine the query)
- Fit naturally into the existing ctrl-/ view-switching flow

**Non-Goals**:
- Paginating beyond 50 results
- Searching issues, PRs, or anything other than repositories
- Advanced query syntax (qualifiers like `language:go`) — fzf input is passed as-is

## Decisions

### Decision 1: fzf `--disabled` + `change:reload` for search mode

When "Search GitHub" is selected, fzf needs to stop filtering locally and instead send each keystroke to the API. fzf supports this via `--disabled` (disables built-in filtering) combined with `change:reload(cmd {q})` (re-runs command on every input change).

The challenge: other views use local filtering (fzf's default). Switching between search and browse modes means toggling `--disabled` on and off.

fzf supports `enable-search` and `disable-search` actions. When the user picks "Search GitHub" via ctrl-/, we bind: `disable-search+reload(...)`. When they switch back to a browse view, we bind: `enable-search+reload(...)`.

**Alternative considered**: Separate fzf instance for search — rejected because it breaks the seamless ctrl-/ switching and duplicates the select/clone flow.

### Decision 2: Debounce via fzf `--delay`

fzf 0.49+ has `--delay <ms>` which delays `change` events. Set `--delay 300` to avoid hammering the API on every keystroke. This is simpler than shell-level debounce.

However, `--delay` affects all views including browse views where it's unnecessary. This is acceptable — 300ms delay on local filtering is imperceptible since the data is already loaded.

**Alternative considered**: Shell-side sleep + PID tracking — fragile and complex for marginal benefit.

### Decision 3: `fetch_search_repos` helper

New helper function:
```bash
fetch_search_repos() {
  local query="${1:-}"
  [ -z "$query" ] && return 0
  gh api "/search/repositories?q=$(printf '%s' "$query" | jq -sRr @uri)&per_page=50" --jq '.items[].full_name'
}
```

URL-encodes the query via `jq`'s `@uri` filter (`jq` is already available as a `gh` dependency). Returns `owner/repo` format, capped at 50 results.

**Alternative considered**: `gh search repos "$query"` — uses the CLI's search subcommand but output parsing is less clean than `--jq`, and it doesn't give direct control over `per_page`.

### Decision 4: View-aware reload wiring

`tses_fetch_view()` already dispatches by view name. Add `Search GitHub` case that calls `fetch_search_repos` with the current fzf query. The tricky part: `reload(...)` in the `change` event passes `{q}` (the query), but `tses_fetch_view` is called from ctrl-/ reload too (where `{q}` is stale/irrelevant for browse views).

Solution: write the current query to `$TSES_QUERY_FILE` from the change event handler. `tses_fetch_view` reads it when in search mode. For browse views, `tses_fetch_view` ignores the query file.

Actually simpler: use two separate reload paths:
- ctrl-/: `reload(tses_fetch_view)` — browse views, ignores query
- change event: `reload(tses_search_or_noop {q})` — only queries API when in search mode, returns nothing otherwise

New helper `tses_search_or_noop`:
```bash
tses_search_or_noop() {
  local view
  view="$(cat "$TSES_VIEW_FILE" 2>/dev/null)" || return 0
  if [ "$view" = "Search GitHub" ]; then
    fetch_search_repos "$1"
  fi
}
```

For browse views, `change` fires but `tses_search_or_noop` returns nothing (no-op). The list is already populated from ctrl-/ reload, so this is harmless — fzf's local filter handles it from the existing data. Wait — that would clear the list. We need to avoid reloading at all for browse views.

Revised approach: bind `change:reload(...)` only when entering search mode, unbind it when leaving. fzf supports `rebind` and `unbind` actions:
- Enter search: `disable-search+unbind(change)+reload(fetch_search_repos {q})+rebind(change)`... No, we need `change` bound permanently in search mode.

Cleanest approach: always bind `change:reload(tses_search_or_noop {q})`, but have `tses_search_or_noop` re-echo the current view's data when not in search mode (preserving local filter). Actually this re-fetches on every keystroke for browse views, which defeats the purpose.

**Final approach**: Use `change:execute-silent(...)` + conditional reload. Or simpler — accept that `--delay 300` + `tses_search_or_noop` returning empty for non-search views means a brief flicker. 

No — the actual cleanest solution: `unbind(change)` when entering browse mode, `rebind(change)` when entering search mode. The `tses_pick_view` → reload flow already handles this: after picking a view, the reload action can include `unbind(change)` or `rebind(change)` based on which view was selected. But we can't conditionally bind from a single action string.

Use two helpers that emit fzf action strings? No — fzf bind actions are static.

**Practical solution**: Always have `change` bound to `reload(tses_search_or_noop {q})`. For browse views, `tses_search_or_noop` re-outputs the cached browse data (write to a cache file during ctrl-/ reload). This way local filtering still works via fzf rebuilding from the full list on each change event. The 300ms delay makes the re-output imperceptible. Browse views re-cat a local file (instant), search view hits the API (300ms delay helps).

## Risks / Trade-offs

- **[Rate limiting]** → GitHub authenticated search: 30 req/min. `--delay 300` means max ~3.3 req/s if typing continuously. Fast typists could hit the limit. Mitigation: 300ms delay naturally throttles; users pause to read results.
- **[jq dependency]** → `jq` ships with `gh` but isn't guaranteed standalone. Mitigation: `gh api --jq` uses built-in jq, no extra dep needed.
- **[Empty initial search]** → When switching to search mode, fzf list is empty until user types. This is expected UX (like a search box). Show placeholder text via `--header` update.

## Open Questions

None — design is straightforward given existing architecture.
