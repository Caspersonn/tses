## Context

tses currently supports `open` and `kill` subcommands. The script already uses fzf for interactive selection, `gh` CLI for GitHub API access, and has an established pattern of action blocks (`if [ "$action" = "..." ]`). The new `pull` action fits cleanly into this structure.

The `gh` CLI must be authenticated (`gh auth login`) before use. All GitHub data fetching relies on `gh api` and `gh repo list`.

## Goals / Non-Goals

**Goals:**
- Single interactive command to browse, clone, and open GitHub repos
- Switchable views (my repos, starred, organizations, recommended) via a filter menu
- Clone into the user's existing directory structure with destination picker
- Allow creating new parent directories inline

**Non-Goals:**
- Non-interactive / scripted clone (use `git clone` directly)
- Managing GitHub auth (user must have `gh auth login` done)
- Syncing or pulling updates for already-cloned repos
- SSH vs HTTPS preference configuration (use whatever `gh` defaults to)

## Decisions

### 1. Seamless fzf-to-fzf flow via `become`

The `pull` subcommand follows a linear flow through four phases, staying inside fzf for phases 1–3 to avoid terminal flashes:

1. **Browse**: fzf shows repos (default: user's own)
2. **Filter**: ctrl-/ opens a nested fzf to switch views (via `execute`)
3. **Destination**: second fzf picks parent directory under BASE_DIR (via `become`)
4. **Clone + open**: `gh repo clone` into chosen dir, prompt to open session (terminal)

Phases 1–3 are seamless: the user never sees the raw terminal between fzf instances. This is achieved by:
- **`execute`** for the view picker (fzf suspends briefly, resumes after pick)
- **`become`** for the repo→destination transition (replaces the main fzf process with the destination picker — no gap)

Phase 4 drops to the terminal intentionally, since clone progress and the open prompt are terminal output.

The `become` action outputs a structured string (`EXISTING:<path>` or `CLONE:<repo>:<dest>`) that the caller parses to determine the next step.

**Why `become` over sequential fzf**: Sequential fzf invocations cause a visible terminal flash between them. `become` replaces the fzf process in-place, so the destination picker appears instantly.

### 2. Use fzf `execute` + `reload` + `transform-header` for the filter menu

Pressing ctrl-/ triggers three chained fzf actions:

1. **`execute(tses_pick_view)`** — nested fzf with terminal access shows view options, writes selection to a temp file. This is fast (<1s), so the brief fzf suspension is acceptable.
2. **`reload(tses_fetch_view)`** — reads the temp file, calls the appropriate fetch helper. fzf stays visible during the API call (shows loading state).
3. **`transform-header(tses_header_view)`** — reads the temp file, returns the header text.

Each helper is a separate exported function with simple, balanced parentheses in the bind string. This avoids two fzf bind parser pitfalls:

- **No shell code in action parens**: fzf uses balanced `()` matching to parse actions. `case` patterns (e.g., `'My repos')`) contain unmatched `)` that break the parser. Keeping logic in helper functions avoids this.
- **No newlines between `)+action(`**: fzf splits bind values on newlines. A newline between `)+` and the next action name breaks the chain.

The menu options:

```
"My repos"
"Starred"
"Organizations"
"Recommended"
```

**Why this over dedicated keybinds per view**: Single keybind is discoverable (shown in header). Adding/removing views doesn't require new keybinds. The nested fzf is searchable itself.

**Alternative rejected — `transform` alone**: Captures stdout, so a nested fzf's TUI rendering gets swallowed instead of displayed.

**Alternative rejected — inline shell in bind actions**: Unmatched parentheses from `case` patterns and nested `reload()/change-header()` calls confuse fzf's paren-matching parser.

**Alternative rejected — static keybinds (ctrl-1/2/3/4)**: Harder to discover, doesn't scale, can't add views without new bindings.

### 3. GitHub API strategy per view

| View | Command | Notes |
|------|---------|-------|
| My repos | `gh repo list <user> --json nameWithOwner --limit 100 -q '.[].nameWithOwner'` | Fast, single call |
| Starred | `gh api /user/starred --jq '.[].full_name'` | Paginated, may need `--paginate` |
| Organizations | `gh api /user/orgs --jq '.[].login'` then `gh repo list <org>` per org | Fans out, ~1 call per org |
| Recommended | `gh api /users/<user>/received_events --jq '[.[] \| select(.type=="WatchEvent" or .type=="ForkEvent") \| .repo.name] \| unique \| .[]'` | Social feed, single call |

**Why `gh repo clone` for the clone step**: Handles SSH/HTTPS based on user's `gh` config. Simpler than constructing `git clone` URLs manually.

### 4. Destination picker with "+ New directory"

After selecting a repo, `become` replaces the main fzf with `tses_pull_select`, which launches a second fzf listing existing parent directories under BASE_DIR. The list is built by finding directories that directly contain repos (parent dirs of `find_repos` output). A special `+ New directory` entry is prepended.

If selected, a `read -rp` prompt asks for the new directory name (relative to BASE_DIR), then `mkdir -p` creates it.

`tses_pull_select` also handles already-cloned detection before showing the destination picker. It outputs a structured result string for the caller to parse.

**Why a second fzf over inline prompt**: Consistent UX with the rest of the tool. Most clones go to existing directories; the "+ New" option is the escape hatch.

**Alternative rejected — auto-derive from GitHub org**: User's directory structure doesn't map 1:1 to GitHub orgs (e.g., `personal/` vs `lkasper/`, `customers/ams/` has no GitHub org equivalent).

### 5. Prefetch org list at startup

On `tses pull` entry, immediately fetch the user's username and org list into temp variables. This avoids a delay when the user opens the filter menu for the first time.

```bash
GH_USER="$(gh api /user --jq '.login')"
GH_ORGS="$(gh api /user/orgs --jq '.[].login')"
```

**Why**: The org list is needed to build the "Organizations" view. Fetching it lazily on ctrl-/ would add visible latency.

### 6. Already-cloned detection

Before cloning, check if a directory matching the repo name already exists under BASE_DIR (using `find_repos`). If found, skip clone and offer to open the session directly.

## Risks / Trade-offs

- **[gh auth required]** → Show clear error if `gh auth status` fails: `"GitHub CLI not authenticated. Run: gh auth login"`
- **[API rate limits]** → Switching views rapidly could hit GitHub API limits. Mitigation: views fetch once and fzf filters locally; no API call on each keystroke.
- **[Org repo fan-out]** → Users in many orgs with large repo counts may see slow "Organizations" load. Mitigation: prefetch at startup, add `--limit` per org.
- **[Recommended feed is shallow]** → `/received_events` only returns recent events (last ~90 days, max 300). May show few results for users who don't follow many people. Acceptable for v1.
- **[writeShellApplication strict mode]** → All new code must work under `set -euo pipefail`. Unset variables and failed commands will exit. Use `${var:-}` patterns and explicit error checks.
