## 1. Search helper

- [x] 1.1 Add `fetch_search_repos` function that takes a query string, URL-encodes it, and calls `gh api /search/repositories?q=...&per_page=50 --jq '.items[].full_name'`
- [x] 1.2 Add `tses_search_or_noop` function that checks `$TSES_VIEW_FILE` — if "Search GitHub", calls `fetch_search_repos "$1"`; otherwise re-cats the cached browse data from `$TSES_BROWSE_CACHE`

## 2. View switching integration

- [x] 2.1 Add "Search GitHub" to `tses_pick_view` menu
- [x] 2.2 Update `tses_fetch_view` to handle "Search GitHub" — clear the list (return empty) and write view name to file
- [x] 2.3 Update `tses_header_view` to return search-mode header text (e.g., "View: Search GitHub | Type to search | ctrl-/ to switch")
- [x] 2.4 Modify browse-view fetch path to cache results to `$TSES_BROWSE_CACHE` file so `tses_search_or_noop` can re-output them

## 3. fzf wiring

- [x] 3.1 Add `--delay 300` to the main fzf invocation
- [x] 3.2 Add `change:reload(tses_search_or_noop {q})` binding to the main fzf
- [x] 3.3 Export new functions (`fetch_search_repos`, `tses_search_or_noop`)
- [x] 3.4 Export `TSES_BROWSE_CACHE` env var and add cleanup to trap

## 4. Verification

- [x] 4.1 Test: switch to "Search GitHub", type a query, confirm results appear from GitHub API
- [x] 4.2 Test: switch back to "My repos" from search mode, confirm local filtering works
- [x] 4.3 Test: select a repo from search results, confirm destination picker and clone flow works
- [x] 4.4 `nix build` succeeds
