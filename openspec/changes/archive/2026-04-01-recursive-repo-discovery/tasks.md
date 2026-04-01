## 1. Update repo discovery

- [x] 1.1 Replace `find` in `list_repos()` with recursive prune pattern: `find "$BASE_DIR" -type d '(' -exec test -e '{}/.git' ';' -print -prune ')' 2>/dev/null`
- [x] 1.2 Replace `find` in `resolve_path()` with the same recursive prune pattern

## 2. Verify

- [x] 2.1 Test that repos at depth 2 (e.g. `personal/tses`) are discovered
- [x] 2.2 Test that repos at depth 3 (e.g. `customers/ams/app`) are discovered
- [x] 2.3 Confirm display shows last 2 path components correctly
