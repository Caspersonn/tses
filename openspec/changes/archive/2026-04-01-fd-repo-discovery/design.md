## Context

Repo discovery currently uses `find -exec test -e '{}/.git'` which forks a subprocess for every directory visited. With 221 repos under `~/git`, this takes ~3.8s. The `-exec test` + `-print -prune` pattern is correct (finds top-level repos, skips subrepos) but the per-directory fork overhead dominates.

Benchmarked alternatives:
- `find -exec test` (current): 3.8s, correct
- `find -name .git` + dedup: 2.3s, correct
- `fd --hidden --no-ignore` + dedup: 0.22s, correct
- `fd --hidden` (gitignore-aware): 0.22s, 1 spurious result

## Goals / Non-Goals

**Goals:**
- Reduce discovery time from ~3.8s to <0.5s
- Maintain exact same repo set (221 top-level repos, no subrepos)
- Keep `fd` hermetically wrapped via Nix flake

**Non-Goals:**
- Caching (adds complexity for marginal gain over 0.2s)
- Removing `findutils` from flake deps (still used by system; low cost to keep)

## Decisions

### Use `fd` instead of `find`

`fd` is a Rust-based parallel directory walker. It uses multiple threads and avoids per-entry subprocess forks, giving ~17x speedup.

**Why not `find -name .git`?** Still single-threaded and must traverse into all directories. Only saves the `test` fork overhead (2.3s vs 3.8s). Not enough improvement.

**Why not `fd` with gitignore awareness (no `--no-ignore`)?** Gives 222 results instead of 221 — one Hugo theme inside a repo isn't gitignored. Relying on `.gitignore` correctness for functional behavior is fragile.

### Post-process dedup with `sort | awk`

`fd` cannot prune at first `.git` match the way `find -exec test -print -prune` does. It finds all 582 `.git` directories including subrepos in `.terraform/modules/`, `node_modules/`, `deps/`, etc.

Solution: sort paths lexicographically, then use awk to skip any path whose parent is already a kept repo. Must check against all kept repos (not just the previous one) because sorted order can interleave siblings between a parent and its nested children.

```
fd --hidden --no-ignore --type d '^\.git$' "$BASE_DIR" \
  | sed 's|/\.git/$||' | sort | awk '{
    skip = 0
    for (i = 1; i <= n; i++) {
      if (substr($0, 1, length(repos[i]) + 1) == repos[i] "/") {
        skip = 1; break
      }
    }
    if (!skip) { n++; repos[n] = $0; print $0 }
  }'
```

**Why not a simple single-prev check?** Fails when a sibling repo sorts between a parent and its nested child (e.g., `webdns` → `webdns-ec2nix` → `webdns/stack/.terraform/...`).

### Add `fd` to flake `runtimeInputs`

`fd` is available in nixpkgs as `fd`. Added alongside existing deps.

## Risks / Trade-offs

- **O(n*m) dedup** (n=582 results, m=221 repos) → awk checks each result against all kept repos. At current scale (582 × 221 ≈ 129k comparisons) this is negligible (<1ms). Would need ~100k repos to matter.
- **`fd` output format** → Trailing slash on directory names (`/path/.git/`). Must use `sed 's|/\.git/$||'` not `sed 's|/\.git$||'`.
