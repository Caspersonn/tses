## Context

`list_repos()` and `resolve_path()` use `find "$BASE_DIR" -type d -maxdepth 3 -name .git` to discover repos. This hard-caps depth and doesn't prevent finding nested repos inside an already-found repo (subrepos/submodules).

## Goals / Non-Goals

**Goals:**
- Recursive repo discovery at any depth under `BASE_DIR`
- Exclude subrepos: once a `.git` is found, don't recurse deeper into that tree
- Keep display as last 2 path components (already the case)

**Non-Goals:**
- Changing the display format
- Supporting multiple base directories
- Performance tuning (repo count is small)

## Decisions

### Use `find -exec test -e '{}/.git' -print -prune` pattern

Replace the current find command with:

```bash
find "$BASE_DIR" -type d '(' -exec test -e '{}/.git' ';' -print -prune ')'
```

For each directory: test if it contains `.git` — if yes, print and prune (stop recursing). This naturally handles both variable depth and subrepo exclusion in one pass.

**Why `-e` not `-d`**: Git submodules use a `.git` file (not directory). `-e` (exists) catches both real repos and submodules.

**Alternatives rejected:**
- `maxdepth 4+`: Still static, still doesn't exclude subrepos
- Manual post-filtering of nested paths: Complex, error-prone, slower

### Apply to both `list_repos()` and `resolve_path()`

Both functions use the same find pattern. Both must be updated to stay consistent.

## Risks / Trade-offs

- **[Slower on deep trees]** → Negligible in practice; `~/git` is bounded. Prune limits traversal.
- **[Symlink loops]** → `find` handles these; not adding `-L` so symlinks to dirs are skipped by default.
