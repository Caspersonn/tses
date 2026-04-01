## Why

`BASE_DIR` is hardcoded in `tses.sh`, requiring users to edit the script source to change the repo scan root. This makes the tool non-portable and awkward to update.

## What Changes

- **BREAKING**: Change usage from `tses {open|kill} [name]` to `tses [--base DIR] {open|kill} [name]`
- Add `--base` flag to specify the repo scan root directory
- Fall back to `$HOME/git` when `--base` is not provided
- Remove the `# change this` comment

## Capabilities

### New Capabilities
- `cli-base-flag`: Support configuring the base directory via a `--base` command-line argument with a sensible default

### Modified Capabilities
<!-- None — no existing specs -->

## Impact

- `tses.sh`: Argument parsing changes — `--base` must be consumed before the action argument
- Usage string updates to reflect new flag
