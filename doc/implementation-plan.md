# Implementation Plan

## Approach

To keep the MVP small, implementation should start by locking down the helper foundation first, then layering `run.sh`, actions, and the example profile on top.
Features that are explicitly out of scope for the MVP should stay out of the initial execution plan and be listed separately as post-MVP work.

## Phase 1

- create `plugin/tmux-plugin-template.tmux`
- define tmux option defaults
- make the key binding launch `scripts/run.sh --profile <name> --target-pane <pane_id>` through `display-popup`

## Phase 2

- create `scripts/core/tmux_options.sh`
- implement tmux option readers and default resolution
- support `popup width`, `popup height`, `prompt`, `action`, `auto-clear-seconds`, and `profile`

## Phase 3

- create `scripts/core/validate.sh`
- validate shared dependencies: `tmux`, `fzf`
- add action-specific dependency checks
- call profile-side `profile_check_dependencies` when present

## Phase 4

- create `scripts/core/errors.sh`
- implement stage-aware error rendering
- append `profile_on_error` output when available
- centralize the wait-before-close behavior

## Phase 5

- create `scripts/core/profile.sh`
- load `scripts/profiles/<name>.sh` safely
- validate the required functions: `profile_source`, `profile_transform`, `profile_resolve`
- add helpers for detecting optional hooks

## Phase 6

- create `scripts/core/fzf.sh`
- implement a shared `fzf` runner for tab-delimited rows
- provide defaults for `--prompt`, `--delimiter`, and `--with-nth`

## Phase 7

- create `scripts/core/clipboard.sh`
- abstract `pbcopy`, `xclip`, and `clip.exe`
- support background auto-clear

## Phase 8

- create `scripts/core/actions.sh`
- implement the `stdout` action
- implement the `clipboard` action through `clipboard.sh`
- implement the `send-keys` action
- prefer profile-specific `profile_action` when defined

## Phase 9

- create `scripts/run.sh`
- parse `--profile` and `--target-pane`
- load core helpers and orchestrate the full `source -> transform -> fzf -> resolve -> action` flow
- add shared popup-visible error handling with keypress wait on failure

## Phase 10

- create `scripts/profiles/example.sh`
- implement one initial example profile
- keep it limited to either `tmux list-sessions` or simple file-line selection
- make it serve as the smallest complete example of `source`, `transform`, and `resolve`

## Phase 11

- create `README.md`
- document installation
- document a minimal configuration example
- document tmux options
- document profile authoring
- document example profile usage
- document the risk of `send-keys`

## Phase 12

- run manual verification
- confirm that the popup opens
- confirm that `fzf` selection works
- confirm that `stdout`, `clipboard`, and `send-keys` all work
- confirm that missing dependencies and profile errors are visible inside the popup

## First Milestone

Once the following pieces exist, the MVP can run end to end without cache.

1. `plugin/tmux-plugin-template.tmux`
2. `scripts/core/tmux_options.sh`
3. `scripts/core/validate.sh`
4. `scripts/core/errors.sh`
5. `scripts/core/profile.sh`
6. `scripts/core/fzf.sh`
7. `scripts/core/clipboard.sh`
8. `scripts/core/actions.sh`
9. `scripts/run.sh`
10. `scripts/profiles/example.sh`

## Notes

- `run.sh` is the integration point on top of the helpers, so a stub can exist early, but the real implementation belongs later in the sequence
- cache is out of scope for the MVP, so it can be deferred entirely at implementation start
- `profile_preview` exists in the design, but is intentionally excluded from the MVP task list
- the `command` action is also out of scope for the MVP and should stay out of the first implementation pass

## Post-MVP Work

- implement the `profile_preview` hook
- implement the `command` action
- implement cache support
- support multiple profile registrations
- evaluate multi-select support
