## 1. Fix tses.sh for strict mode compatibility

- [x] 1.1 Run shellcheck on tses.sh and fix any errors (writeShellApplication injects `set -euo pipefail`)
- [x] 1.2 Verify tses.sh works under `set -euo pipefail`

## 2. Create flake.nix

- [x] 2.1 Create flake.nix with flake-utils input and `writeShellApplication` derivation wrapping tses.sh with all runtime deps (tmux, fzf, findutils, gawk, gnused, gnugrep, coreutils)

## 3. Verify

- [x] 3.1 Run `nix build` and confirm it succeeds (shellcheck passes, derivation builds)
- [x] 3.2 Run the built `./result/bin/tses` and confirm usage output works
