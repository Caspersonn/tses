## Why

Repos live at variable depth under `BASE_DIR` — `personal/tses` is 2 levels deep, `customers/ams/app` is 3. The current `find -maxdepth 3` is fragile (misses deeper repos) and doesn't exclude subrepos (submodules / nested `.git` dirs).

## What Changes

- Replace static `maxdepth 3` find with recursive search that prunes at `.git` boundaries
- Subrepos (submodules, nested git dirs) are automatically excluded by pruning
- Display stays as last 2 path components (e.g. `ams/app`, `personal/tses`)

## Capabilities

### New Capabilities

- `repo-discovery`: Recursive git repo discovery with subrepo pruning

### Modified Capabilities

_None — `env-config` requirements unchanged, only the find implementation changes._

## Impact

- `tses.sh`: `list_repos()` and `resolve_path()` functions change their `find` command
