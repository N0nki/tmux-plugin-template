# Design

## Purpose

This design defines a generic tmux plugin template for search-and-select flows built with `tmux display-popup + fzf`.
The template core provides the shared execution flow and runtime foundation, while concrete use cases are added as `profiles`.

## Design Principles

- keep the core generic
- keep profile logic use-case specific
- stay shell-based and lightweight
- expose essential behavior through tmux options
- keep errors visible inside the popup
- make each selection flow explicit and staged

## System Structure

The template is split into three layers.

### 1. tmux layer

This layer is loaded as a tmux plugin and is responsible for key bindings and popup launch.

- reading tmux options
- registering key bindings
- setting popup size
- selecting the target profile

### 2. core layer

This layer contains the shared popup runtime.

- dependency checks
- profile loading
- orchestration of source, transform, fzf, resolve, and action
- error handling
- shared helpers such as clipboard and cache

### 3. profile layer

This layer implements a concrete use case.

- defining the data source
- formatting rows for `fzf`
- resolving a selected row
- overriding or extending post-selection behavior

## Directory Structure

The initial structure should look like this.

```text
.
├── doc/
│   ├── requirements.ja.md
│   ├── requirements.md
│   ├── design.ja.md
│   └── design.md
├── plugin/
│   └── tmux-plugin-template.tmux
├── scripts/
│   ├── run.sh
│   ├── core/
│   │   ├── actions.sh
│   │   ├── cache.sh
│   │   ├── clipboard.sh
│   │   ├── errors.sh
│   │   ├── fzf.sh
│   │   ├── profile.sh
│   │   ├── tmux_options.sh
│   │   └── validate.sh
│   └── profiles/
│       └── example.sh
└── README.md
```

## Execution Flow

One popup flow is composed as follows.

```text
tmux key binding
  -> display-popup
  -> scripts/run.sh --profile <name> --target-pane <pane_id>
  -> core: load config
  -> core: validate dependencies
  -> core: load profile
  -> profile_source
  -> profile_transform
  -> fzf
  -> profile_resolve
  -> action
```

Each stage is responsible for the following.

- `profile_source`: emits raw data to stdout
- `profile_transform`: converts raw data into rows for `fzf`
- `fzf`: handles interactive selection
- `profile_resolve`: converts the selected row into the final value for the action
- `action`: sends the value to clipboard, send-keys, stdout, or a custom command

For `send-keys`, the target pane must be the pane that opened the popup, not the popup pane itself.
The tmux layer therefore needs to resolve `#{pane_id}` at launch time and pass it explicitly into `run.sh`.

## Profile Contract

Profiles live in `scripts/profiles/*.sh` and provide a convention-based set of shell functions.

### Required functions

```bash
profile_source
profile_transform
profile_resolve
```

### Optional functions

```bash
profile_check_dependencies
profile_preview
profile_action
profile_on_error
profile_cache_key
profile_cache_get
profile_is_cacheable
```

### Required function contracts

#### `profile_source`

- Input: none
- Output: raw data to stdout
- Failure: exit non-zero and print the reason to stderr

#### `profile_transform`

- Input: stdout from `profile_source`
- Output: row data for `fzf`
- A row may include both display fields and an internal value separated by a delimiter
- The initial implementation standardizes on tab-separated rows

#### `profile_resolve`

- Input: a single row selected by `fzf`
- Output: the final value to pass to the action
- Failure: exit non-zero and print the reason to stderr

### Optional function roles

#### `profile_check_dependencies`

- validates profile-specific external commands
- called after core-level dependency checks

#### `profile_preview`

- Input: the row currently highlighted in `fzf`
- Output: content to render in the preview window
- the core connects this function to `fzf --preview` through a small wrapper
- this avoids making profiles return raw shell command strings with ambiguous quoting

#### `profile_action`

- allows a profile to fully control the final action
- if undefined, the core uses the shared action implementation

#### `profile_on_error`

- allows a profile to print additional troubleshooting guidance

#### `profile_cache_key`

- returns the cache key used for the profile
- if undefined, the core uses the profile name

#### `profile_cache_get`

- emits only the data that is safe to persist in cache
- if undefined, the core does not cache profile data

#### `profile_is_cacheable`

- returns `0` when the profile explicitly allows caching
- if undefined, the profile is treated as non-cacheable

## Row Format

The initial implementation uses tab-separated rows for `fzf`.

Example:

```text
display_name<TAB>description<TAB>raw_id
```

The rules are:

- left-side fields are for display
- the last field may be used as an internal value for `resolve`
- `fzf --with-nth` controls which fields are visible
- `fzf --delimiter` defaults to tab
- profiles must not embed raw tabs or newlines into row fields
- if data may contain those characters, rows should carry only stable identifiers and fetch details later in `resolve` or `preview`

This keeps display text separate from internal identifiers.

## Action Model

The core provides a shared set of actions.

### `stdout`

- prints the resolved value as-is
- useful as the simplest debug behavior

### `clipboard`

- abstracts `pbcopy`, `xclip`, and `clip.exe`
- supports configurable auto-clear

### `send-keys`

- uses the pane that launched the popup
- the core receives it explicitly through an environment variable such as `TMUX_POPUP_TEMPLATE_TARGET_PANE`
- should allow future override via tmux option if needed

### `command`

- passes the resolved value into an arbitrary command
- the initial design should prefer passing it as a single argument for safety
- this action is a future extension and is not included in the MVP

## tmux Option Design

The initial version should expose at least these options.

```text
@popup-template-key
@popup-template-profile
@popup-template-popup-width
@popup-template-popup-height
@popup-template-prompt
@popup-template-action
@popup-template-auto-clear-seconds
@popup-template-use-cache
@popup-template-cache-age
```

### Roles

- `@popup-template-key`: launch key
- `@popup-template-profile`: profile name to run
- `@popup-template-popup-width`: popup width
- `@popup-template-popup-height`: popup height
- `@popup-template-prompt`: `fzf` prompt
- `@popup-template-action`: `stdout`, `clipboard`, `send-keys`, `command`
- `@popup-template-auto-clear-seconds`: clipboard auto-clear timeout
- `@popup-template-use-cache`: enable cache
- `@popup-template-cache-age`: cache lifetime

Profile-specific options should be added with a profile-specific prefix.

Example:

```text
@popup-template-example-file
@popup-template-example-command
```

## Cache Design

Cache is optional in the initial implementation.

### Purpose

- avoid re-running expensive source commands
- improve popup responsiveness

### Approach

- cache only data that the profile explicitly marks as safe
- store cache files under `/tmp`
- separate cache files by user and profile
- write using `mktemp + chmod 600 + mv`
- bypass cache entirely when disabled
- unless `profile_cache_get` is implemented, the core does not cache any profile data

### Example path

```text
/tmp/tmux-popup-template-<user>-<profile>.cache
```

## Error Handling Design

Error handling is centralized in the core.

### Rules

- identify the failing stage clearly
- print the error inside the popup
- do not exit immediately; wait for a key press
- include optional profile-specific troubleshooting text

### Example error output

```text
Error in profile_resolve
<stderr message>

Press any key to close...
```

## Dependency Design

The core validates the minimum required tools.

- `tmux`
- `fzf`

Additional dependencies are validated per action or profile.

- `clipboard` action: `pbcopy` or `xclip` or `clip.exe`
- profile-specific CLI: checked in `profile_check_dependencies`

## Security Approach

- avoid risky shell string interpolation where possible
- prefer arrays or single-argument passing when building commands
- treat caching secret values as disallowed by default
- provide clipboard auto-clear as a shared action feature
- document the risk of `send-keys` clearly in the README

## MVP Design

The first implementation should include only the following.

### In scope

- launching a single profile
- the shared `source -> transform -> fzf -> resolve -> action` flow
- three actions: `stdout`, `clipboard`, `send-keys`
- tmux options for popup size and prompt
- popup-visible dependency and runtime errors
- one bundled example profile

### Out of scope

- registering multiple profiles at once
- advanced preview customization
- `command` action
- cache
- multi-select
- multi-step flows

## Example Profile Direction

The first bundled example profile should be intentionally simple.

Examples:

- choose a line from `cat <file>`
- choose a session from `tmux list-sessions`

Its purpose is to demonstrate the extension points with minimal complexity.

## Implementation Order

1. create `plugin/tmux-plugin-template.tmux`
2. implement the shared flow in `scripts/run.sh`
3. split shared logic into `scripts/core/` helpers
4. add `scripts/profiles/example.sh`
5. document profile authoring in the README
6. add cache and custom actions later if needed

## Future Extensions

- multiple profile registrations
- preview hooks
- custom command actions
- multi-select
- structured row formats such as JSON Lines
- self-describing profile metadata

## Decision

This template uses shell-function-based profiles rather than a config-only model.
The reasoning is:

- it stays simple within a shell-based tmux plugin
- it preserves flexibility for source, resolve, and action behavior
- it is easy to adapt from existing shell plugins such as `tmux-op-secure`
- it keeps the initial implementation small and understandable

The first version prioritizes simplicity and clarity over maximum flexibility.
