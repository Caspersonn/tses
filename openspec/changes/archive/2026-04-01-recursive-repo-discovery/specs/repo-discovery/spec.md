## ADDED Requirements

### Requirement: Recursive repo discovery
The system SHALL discover git repos at any depth under `BASE_DIR` by recursively searching for directories containing `.git`.

#### Scenario: Repo at depth 2
- **WHEN** a repo exists at `BASE_DIR/personal/tses/.git`
- **THEN** it SHALL be discovered and displayed as `personal/tses`

#### Scenario: Repo at depth 3
- **WHEN** a repo exists at `BASE_DIR/customers/ams/app/.git`
- **THEN** it SHALL be discovered and displayed as `ams/app`

#### Scenario: Repo at depth 4+
- **WHEN** a repo exists at `BASE_DIR/org/team/project/repo/.git`
- **THEN** it SHALL be discovered and displayed as `repo` with its parent (e.g. `project/repo`)

### Requirement: Subrepo exclusion
The system SHALL NOT discover repos nested inside another repo. Once a `.git` is found in a directory, that directory's subtree SHALL be pruned from further search.

#### Scenario: Submodule inside a repo
- **WHEN** `BASE_DIR/personal/tses/.git` exists AND `BASE_DIR/personal/tses/vendor/lib/.git` exists
- **THEN** only `personal/tses` SHALL appear in the results; `vendor/lib` SHALL be excluded

#### Scenario: Nested git init inside a repo
- **WHEN** a user has run `git init` inside a subdirectory of an existing repo
- **THEN** only the outermost repo SHALL appear in the results
