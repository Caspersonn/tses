## 1. Authentication and Setup

- [x] 1.1 Add `gh auth status` check at the start of the `pull` action — exit with `"GitHub CLI not authenticated. Run: gh auth login"` if it fails
- [x] 1.2 Prefetch `GH_USER` and `GH_ORGS` at pull entry using `gh api /user` and `gh api /user/orgs`

## 2. Repo Fetching Helpers

- [x] 2.1 Add `fetch_my_repos()` — calls `gh repo list "$GH_USER" --json nameWithOwner --limit 100 -q '.[].nameWithOwner'`
- [x] 2.2 Add `fetch_starred_repos()` — calls `gh api /user/starred --paginate --jq '.[].full_name'`
- [x] 2.3 Add `fetch_org_repos()` — loops over `$GH_ORGS`, calls `gh repo list <org>` per org, merges output
- [x] 2.4 Add `fetch_recommended_repos()` — calls `gh api /users/$GH_USER/received_events` with jq filter for WatchEvent/ForkEvent, deduplicates

## 3. Browse Phase (Main fzf)

- [x] 3.1 Add the `pull` action block — launch fzf with `fetch_my_repos` as the default source, displaying `owner/repo` format
- [x] 3.2 Bind ctrl-/ to open a nested fzf filter menu listing "My repos", "Starred", "Organizations", "Recommended"
- [x] 3.3 Wire filter menu selection to `reload` the main fzf with the corresponding fetch helper

## 4. Destination Phase

- [x] 4.1 Add `pick_destination()` — build list of existing parent directories from `find_repos` output, prepend `+ New directory`, show in fzf
- [x] 4.2 Handle `+ New directory` selection — prompt for name with `read -rp`, create with `mkdir -p "$BASE_DIR/<name>"`

## 5. Clone and Open Phase

- [x] 5.1 Check if repo already exists locally (match repo name against `find_repos` output) — if found, skip clone and offer to open
- [x] 5.2 Clone with `gh repo clone <owner/repo> <destination>/<repo_name>`
- [x] 5.3 After successful clone, prompt user to open a tmux session — reuse existing open logic if confirmed

## 6. Integration

- [x] 6.1 Update usage string to `tses [--base DIR] {open [name] | kill [name] | pull}`
- [x] 6.2 Add `gh` to `runtimeInputs` in `flake.nix`

## 7. Verification

- [x] 7.1 Run `tses pull` — confirm fzf shows user's repos and ctrl-/ filter menu works
- [x] 7.2 Select a repo and verify destination picker shows existing directories plus `+ New directory`
- [x] 7.3 Clone a repo and verify it lands in the correct directory
- [x] 7.4 Run `nix build` and verify the built binary has `gh` available
