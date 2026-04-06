## ADDED Requirements

### Requirement: Live GitHub search from pull interface

The `tses pull` interface SHALL support a "Search GitHub" view where typing queries GitHub's search API in real-time instead of filtering locally. Results SHALL be capped at 50 repositories per query, sorted by GitHub's relevance ranking. Results SHALL display as `owner/repo`.

#### Scenario: Search returns results
- **WHEN** the user switches to "Search GitHub" view and types `terraform-aws`
- **THEN** fzf reloads with up to 50 repos matching `terraform-aws` from GitHub's search API, displayed as `owner/repo`

#### Scenario: Search with empty query
- **WHEN** the user switches to "Search GitHub" view and has not typed anything
- **THEN** the fzf list SHALL be empty and the header SHALL indicate that the user should type to search

#### Scenario: Debounced API calls
- **WHEN** the user types rapidly in search mode
- **THEN** the system SHALL debounce requests (minimum 300ms between API calls) to avoid excessive API usage

#### Scenario: Result limit
- **WHEN** a search query matches more than 50 repositories
- **THEN** only the top 50 results by relevance SHALL be displayed

### Requirement: Search view preserves pull workflow

After selecting a repo from search results, the existing destination picker, clone, and open-session flow SHALL work identically to other views.

#### Scenario: Clone from search result
- **WHEN** the user selects a repo from search results
- **THEN** the destination picker appears, followed by clone and open-session prompt, identical to selecting from any other view
