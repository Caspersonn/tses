### Requirement: Flake exposes tses as default package

The flake SHALL expose `packages.<system>.default` that installs a `tses` executable.

#### Scenario: Install via nix profile
- **WHEN** a user runs `nix profile install github:user/tses`
- **THEN** the `tses` command is available on their `PATH`

#### Scenario: Use as flake input
- **WHEN** another flake includes tses as an input and adds it to packages
- **THEN** the `tses` command is available in that flake's environment

### Requirement: Runtime dependencies are hermetically wrapped

The installed `tses` binary SHALL have all runtime dependencies (tmux, fzf, fd, findutils, gawk, gnused, gnugrep, coreutils) available without relying on the user's system `PATH`.

#### Scenario: Run on minimal system
- **WHEN** `tses` is installed via Nix on a system that has none of the runtime deps in `PATH`
- **THEN** `tses open` still functions correctly (fzf picker appears, tmux session is created)

### Requirement: Multi-platform support

The flake SHALL produce packages for x86_64-linux, aarch64-linux, x86_64-darwin, and aarch64-darwin.

#### Scenario: Build on each supported platform
- **WHEN** `nix build` is run on any of the four supported platforms
- **THEN** the build succeeds and produces a working `tses` executable

### Requirement: Script passes shellcheck

Since `writeShellApplication` runs shellcheck at build time, the script SHALL pass shellcheck without errors.

#### Scenario: Nix build runs shellcheck
- **WHEN** `nix build` is run
- **THEN** shellcheck runs on the script content and reports no errors
