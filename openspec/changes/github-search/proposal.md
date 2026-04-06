## Why

`tses pull` currently shows 4 pre-fetched views (my repos, starred, organizations, recommended). Typing in fzf only filters locally against those lists. There is no way to discover repos outside those views — if a user wants to find an arbitrary public repo (or one from an org they don't belong to), they have to leave the tool and go to github.com.

## What Changes

- Add a **"Search GitHub"** view to the ctrl-/ filter menu. When selected, typing in the fzf prompt triggers a live search against GitHub's search API (`gh api /search/repositories?q=...`) instead of filtering locally.
- Use fzf's `change:reload(...)` binding to re-query the API as the user types (debounced via `--delay` or `sleep`).
- Search results display as `owner/repo` like other views, with optional description or star count for disambiguation.

## Capabilities

### New Capabilities
- `github-search`: Live GitHub repository search from within the pull interface

### Modified Capabilities
- `github-pull`: Add "Search GitHub" entry to the filter menu and wire up dynamic reload behavior for the search view

## Impact

- `tses.sh`: New fetch helper, modified filter menu, conditional fzf rebind for search mode
- No new dependencies (uses existing `gh` CLI)
- API rate: authenticated search is 30 req/min — debounce is important
