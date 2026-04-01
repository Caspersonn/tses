## Why

tses has no reproducible installation method. Users must manually ensure all runtime dependencies (bash, tmux, fzf, findutils, gawk, gnused, gnugrep, coreutils) are available. A Nix flake provides a single `nix profile install` or flake input that handles everything.

## What Changes

- Add a `flake.nix` at the repo root that packages tses as a Nix derivation
- The derivation wraps `tses.sh` with all runtime dependencies on `PATH` (hermetic)
- Exposes `packages.<system>.default` for standard Nix installation
- Multi-system support: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin

## Capabilities

### New Capabilities

- `nix-packaging`: Nix flake derivation that installs tses as a wrapped script with hermetic runtime dependencies

### Modified Capabilities

None.

## Impact

- New file: `flake.nix` at repo root
- No changes to `tses.sh` itself
- Adds Nix as an optional installation method (does not affect non-Nix users)
