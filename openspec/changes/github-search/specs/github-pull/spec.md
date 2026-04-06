## MODIFIED Requirements

### Requirement: Filter menu switches views

Pressing ctrl-/ SHALL open a nested fzf menu with available views. Selecting a view SHALL reload the main fzf list with repos from that source. The menu SHALL include: My repos, Starred, Organizations, Recommended, and Search GitHub.

#### Scenario: Switch to starred view
- **WHEN** the user presses ctrl-/ and selects "Starred"
- **THEN** the main list reloads with the user's starred repos and fzf local filtering is enabled

#### Scenario: Switch to organizations view
- **WHEN** the user presses ctrl-/ and selects "Organizations"
- **THEN** the main list reloads with repos from all GitHub organizations the user belongs to, merged into a single list, and fzf local filtering is enabled

#### Scenario: Switch to recommended view
- **WHEN** the user presses ctrl-/ and selects "Recommended"
- **THEN** the main list reloads with repos from the user's activity feed (repos recently starred or forked by people they follow) and fzf local filtering is enabled

#### Scenario: Switch back to my repos
- **WHEN** the user presses ctrl-/ and selects "My repos"
- **THEN** the main list reloads with the user's own repos and fzf local filtering is enabled

#### Scenario: Switch to search view
- **WHEN** the user presses ctrl-/ and selects "Search GitHub"
- **THEN** the main list is cleared, fzf local filtering is disabled, the header updates to indicate search mode, and typing triggers API search queries
