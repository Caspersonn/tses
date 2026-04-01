## MODIFIED Requirements

### Requirement: Recursive repo discovery
The system SHALL discover git repos at any depth under `BASE_DIR` by using `fd` to find `.git` directories, then deduplicating to retain only top-level repos.

#### Scenario: Repo at depth 2
- **WHEN** a repo exists at `BASE_DIR/personal/tses/.git`
- **THEN** it SHALL be discovered and displayed as `personal/tses`

#### Scenario: Repo at depth 3
- **WHEN** a repo exists at `BASE_DIR/customers/ams/app/.git`
- **THEN** it SHALL be discovered and displayed as `ams/app`

#### Scenario: Repo at depth 4+
- **WHEN** a repo exists at `BASE_DIR/org/team/project/repo/.git`
- **THEN** it SHALL be discovered and displayed as `repo` with its parent (e.g. `project/repo`)

#### Scenario: Performance
- **WHEN** `list_repos()` is called against a BASE_DIR containing 200+ repos
- **THEN** results SHALL be returned in under 0.5 seconds

### Requirement: Subrepo exclusion
The system SHALL NOT discover repos nested inside another repo. After collecting all `.git` directories, the dedup step SHALL exclude any path that is a descendant of an already-kept repo.

#### Scenario: Submodule inside a repo
- **WHEN** `BASE_DIR/personal/tses/.git` exists AND `BASE_DIR/personal/tses/vendor/lib/.git` exists
- **THEN** only `personal/tses` SHALL appear in the results; `vendor/lib` SHALL be excluded

#### Scenario: Nested git init inside a repo
- **WHEN** a user has run `git init` inside a subdirectory of an existing repo
- **THEN** only the outermost repo SHALL appear in the results

#### Scenario: Terraform modules inside a repo
- **WHEN** `.terraform/modules/` inside a repo contains directories with their own `.git`
- **THEN** only the outermost repo SHALL appear in the results
