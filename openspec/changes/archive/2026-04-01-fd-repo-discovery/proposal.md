## Why

Repo discovery takes ~3.8s for 221 repos because `find -exec test -e '{}/.git'` forks a subprocess for every directory traversed. This makes the fzf picker feel sluggish on every invocation.

## What Changes

- Replace `find -exec test` with `fd` for repo discovery in both `list_repos()` and `resolve_path()`
- Add `fd` as a runtime dependency in the Nix flake
- Use `fd --hidden --no-ignore --type d '^\.git$'` piped through `sort | awk` dedup to prune subrepos, reducing discovery time from 3.8s to ~0.2s (17x faster)

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `repo-discovery`: Implementation changes from `find -exec test` to `fd` with post-processing dedup. Same behavioral contract (recursive discovery, subrepo exclusion).
- `nix-packaging`: `fd` added as a runtime dependency.

## Impact

- `tses.sh`: Both `list_repos()` and `resolve_path()` functions rewritten
- `flake.nix`: `fd` added to `runtimeInputs`
- Runtime: requires `fd` (fd-find) on PATH
