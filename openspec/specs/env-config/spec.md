### Requirement: Base directory is configurable via --base flag
The script SHALL accept an optional `--base DIR` flag before the action argument to set the repo scan root. If `--base` is not provided, it SHALL default to `$HOME/git`.

#### Scenario: --base is provided
- **WHEN** the user runs `tses --base /path/to/repos open`
- **THEN** the script MUST scan `/path/to/repos` for git repositories

#### Scenario: --base is not provided
- **WHEN** the user runs `tses open` without `--base`
- **THEN** the script MUST scan `$HOME/git` for git repositories

#### Scenario: --base points to non-existent directory
- **WHEN** `--base` is set to a path that does not exist
- **THEN** the script MUST behave the same as today (find returns no results, fzf shows empty list)

### Requirement: Usage string reflects --base flag
The usage message SHALL show the `--base` option.

#### Scenario: Invalid usage
- **WHEN** the user runs `tses` with an invalid action
- **THEN** the usage message MUST include `[--base DIR]` in the syntax
