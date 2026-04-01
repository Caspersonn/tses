## Context

tses is a single Bash script with runtime dependencies on bash, tmux, fzf, findutils, gawk, gnused, gnugrep, and coreutils. There is no build step. The goal is to package it as a Nix flake so users can install it reproducibly.

## Goals / Non-Goals

**Goals:**
- Provide a `flake.nix` that builds a hermetically wrapped `tses` binary
- All runtime dependencies are injected into the wrapper's `PATH`
- Support Linux and macOS (x86_64 and aarch64)

**Non-Goals:**
- NixOS module or home-manager module (future work)
- Modifying `tses.sh` to accommodate Nix
- Supporting non-Nix installation methods in this change

## Decisions

### 1. Use `writeShellApplication` over `stdenv.mkDerivation` + `makeWrapper`

`writeShellApplication` automatically:
- Wraps the script with specified runtime deps on `PATH`
- Sets a proper bash shebang from nixpkgs
- Runs `shellcheck` at build time (free lint)

This is simpler than a manual `mkDerivation` + `wrapProgram` for a single-script tool. The tradeoff is less flexibility, but tses doesn't need it.

**Alternative considered:** `stdenv.mkDerivation` with `makeWrapper` — more boilerplate for the same result. Would be appropriate if tses had a build step or multiple files.

### 2. Use `flake-utils.lib.eachDefaultSystem` for multi-platform support

Avoids manually repeating the package definition for each system. `eachDefaultSystem` covers x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin.

**Alternative considered:** No helper (manual system enumeration) — verbose but zero extra inputs. The convenience of `flake-utils` is worth the single extra input.

### 3. Runtime dependencies list

The wrapped `PATH` SHALL include: `bash`, `tmux`, `fzf`, `findutils`, `gawk`, `gnused`, `gnugrep`, `coreutils`.

These are derived from the commands used in `tses.sh`: `find`, `sed`, `awk`, `grep`, `head`, `basename`, `cut`, `fzf`, `tmux`.

## Risks / Trade-offs

- [shellcheck may fail on current `tses.sh`] → Fix any issues as part of implementation. The script is small so this is low risk.
- [`writeShellApplication` injects `set -euo pipefail`] → tses.sh currently has no `set` flags. Need to verify the script works under strict mode. If not, fix the script or fall back to `mkDerivation`.
- [flake-utils adds an input dependency] → Acceptable for a dev tool; widely used and stable.
