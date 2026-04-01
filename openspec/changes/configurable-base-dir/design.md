## Context

`tses.sh` hardcodes `BASE_DIR="$HOME/git"` on line 3. Users must edit the script source to change it. The current argument structure is `tses {open|kill} [name]`.

## Goals / Non-Goals

**Goals:**
- Allow users to specify the base directory per-invocation via `--base`
- Preserve backward compatibility (`$HOME/git` remains the default)

**Non-Goals:**
- Environment variable support
- Config file support
- Multi-directory scanning

## Decisions

**Use `--base DIR` flag parsed before the action argument**

New usage: `tses [--base DIR] {open|kill} [name]`

Parse `--base` at the top of the script before reading `action` and `arg_name`:
```bash
BASE_DIR="$HOME/git"
if [ "$1" = "--base" ]; then
  BASE_DIR="$2"
  shift 2
fi
action="$1"
arg_name="$2"
```

*Alternatives considered:*
- Environment variable (`TSES_BASE_DIR`): Invisible at call site; harder to script with multiple roots.
- Positional argument: Ambiguous — conflicts with existing `action` / `name` positions.
- `--base=DIR` (equals form): Adds parsing complexity for no real benefit in a simple script.

## Risks / Trade-offs

- [Risk] `--base` must come before the action → Enforced by parse order; wrong order falls through to "invalid arg" usage message.
- [Trade-off] Slightly more verbose invocation vs. editing source → Acceptable for a tool you alias or bind to a key anyway.
