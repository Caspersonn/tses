## MODIFIED Requirements

### Requirement: Runtime dependencies are hermetically wrapped

The installed `tses` binary SHALL have all runtime dependencies (tmux, fzf, fd, findutils, gawk, gnused, gnugrep, coreutils) available without relying on the user's system `PATH`.

#### Scenario: Run on minimal system
- **WHEN** `tses` is installed via Nix on a system that has none of the runtime deps in `PATH`
- **THEN** `tses open` still functions correctly (fzf picker appears, tmux session is created)
