## ADDED Requirements

### Requirement: Interactive repo browsing with fzf

The `tses pull` subcommand SHALL open an fzf interface that displays GitHub repos. The default view SHALL show the authenticated user's own repos. Typing in fzf SHALL filter the current view locally (no additional API calls).

#### Scenario: Default view shows user's repos
- **WHEN** the user runs `tses pull`
- **THEN** fzf opens with a list of repos from the user's GitHub account, displayed as `owner/repo`

#### Scenario: Local filtering
- **WHEN** the user types in the fzf prompt
- **THEN** the displayed list is filtered locally against the current view's results

### Requirement: Filter menu switches views

Pressing ctrl-/ SHALL open a nested fzf menu with available views. Selecting a view SHALL reload the main fzf list with repos from that source. The menu SHALL include: My repos, Starred, Organizations, and Recommended.

#### Scenario: Switch to starred view
- **WHEN** the user presses ctrl-/ and selects "Starred"
- **THEN** the main list reloads with the user's starred repos

#### Scenario: Switch to organizations view
- **WHEN** the user presses ctrl-/ and selects "Organizations"
- **THEN** the main list reloads with repos from all GitHub organizations the user belongs to, merged into a single list

#### Scenario: Switch to recommended view
- **WHEN** the user presses ctrl-/ and selects "Recommended"
- **THEN** the main list reloads with repos from the user's activity feed (repos recently starred or forked by people they follow)

#### Scenario: Switch back to my repos
- **WHEN** the user presses ctrl-/ and selects "My repos"
- **THEN** the main list reloads with the user's own repos

### Requirement: Destination directory picker

After selecting a repo, a second fzf SHALL display existing parent directories under BASE_DIR that contain repos. A "+ New directory" option SHALL be prepended to the list.

#### Scenario: Pick existing directory
- **WHEN** the user selects a repo and then picks an existing parent directory (e.g., `personal/`)
- **THEN** the repo is cloned into that directory (e.g., `~/git/personal/<repo>`)

#### Scenario: Create new directory
- **WHEN** the user selects "+ New directory"
- **THEN** the system prompts for a directory name relative to BASE_DIR, creates it with `mkdir -p`, and clones the repo into it

### Requirement: Clone and open session

After selecting a destination, the system SHALL clone the repo using `gh repo clone`. After cloning, the system SHALL prompt the user to open a tmux session.

#### Scenario: Successful clone and open
- **WHEN** the clone completes successfully and the user confirms opening
- **THEN** a tmux session is created for the repo using existing `tses open` logic

#### Scenario: Successful clone without open
- **WHEN** the clone completes and the user declines opening
- **THEN** the script exits without creating a tmux session

#### Scenario: Repo already exists locally
- **WHEN** the selected repo already exists under BASE_DIR
- **THEN** the clone is skipped and the user is offered to open the existing repo's session

### Requirement: GitHub CLI authentication check

The `tses pull` subcommand SHALL verify that `gh` is authenticated before proceeding. If not authenticated, it SHALL exit with a clear error message.

#### Scenario: Not authenticated
- **WHEN** the user runs `tses pull` and `gh auth status` fails
- **THEN** the script prints `"GitHub CLI not authenticated. Run: gh auth login"` and exits with code 1

### Requirement: Updated usage string

The usage output SHALL include the `pull` subcommand.

#### Scenario: Show usage with pull
- **WHEN** the user runs `tses` with no arguments or an invalid argument
- **THEN** the output reads `Usage: tses [--base DIR] {open [name] | kill [name] | pull}`
