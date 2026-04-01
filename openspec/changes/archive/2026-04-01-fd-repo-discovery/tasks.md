## 1. Update tses.sh

- [x] 1.1 Replace `find -exec test` with `fd` + `sort` + `awk` dedup in `list_repos()`
- [x] 1.2 Replace `find -exec test` with `fd` + `sort` + `grep` dedup in `resolve_path()`

## 2. Update Nix flake

- [x] 2.1 Add `fd` to `runtimeInputs` in `flake.nix`

## 3. Verify

- [x] 3.1 Run `list_repos` and confirm 221 repos returned in under 0.5s
- [x] 3.2 Run `resolve_path` with a known repo name and confirm correct full path
- [x] 3.3 Run `nix build` and test the built binary
