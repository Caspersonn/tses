## Why

Cloning GitHub repos into the correct directory under `~/git` is a manual, error-prone process. The user must find the repo, navigate to the right parent directory, run `git clone`, then open a session. This should be a single interactive command.

## What Changes

- Add `tses pull` subcommand with an fzf-based TUI for browsing and cloning GitHub repos
- Default view shows the user's own repos; a filter menu (single keybind, ctrl-/) switches between views:
  - **My repos** — `gh repo list`
  - **Starred** — starred repos
  - **Organizations** — repos from all orgs the user belongs to, merged
  - **Recommended** — repos from the user's activity feed (stars/forks by people they follow)
- Filter menu options are fetched dynamically from `gh` (orgs adapt as memberships change)
- Typing in the main fzf filters the current view locally
- After selecting a repo, a second fzf picks the destination directory (existing parent dirs under BASE_DIR)
- A "+ New directory" option allows creating a new parent directory inline
- After cloning, prompt to open a tmux session via existing `tses open` logic
- If the repo already exists locally, skip clone and offer to open
- Adds `gh` as a runtime dependency

## Capabilities

### New Capabilities
- `github-pull`: Interactive GitHub repo browsing, cloning into the local directory structure, and session opening

### Modified Capabilities
- `nix-packaging`: Adding `gh` (GitHub CLI) to hermetic runtime dependencies

## Impact

- **Code**: New `pull` action block in `tses.sh`, new helper functions for GitHub API calls and fzf interactions
- **Dependencies**: Requires `gh` CLI authenticated (`gh auth login`), adds `gh` to flake.nix runtimeInputs
- **Usage string**: Updated to include `pull` subcommand
