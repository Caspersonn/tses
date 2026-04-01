## 1. Add --base flag parsing

- [x] 1.1 Add `--base` flag parsing before `action="$1"` in `tses.sh` (shift args after consuming)
- [x] 1.2 Remove the hardcoded `# change this` comment

## 2. Update usage string

- [x] 2.1 Update the usage message to `tses [--base DIR] {open [name] | kill [name]}`

## 3. Verify

- [x] 3.1 Test without `--base` — should default to `$HOME/git`
- [x] 3.2 Test with `--base /some/path` — should scan that path
