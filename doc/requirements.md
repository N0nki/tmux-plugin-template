# Requirements

## Purpose

This plugin template should provide a reusable `tmux display-popup + fzf` interaction pattern.
The core goal is to make it easy to build tmux plugins that:

- open a popup from a tmux key binding
- search arbitrary data with `fzf`
- pass the selected result to a follow-up action

The `tmux-op-secure` plugin is the reference example, but 1Password-specific behavior is not part of the template core.

## Non-Goals

- implementing a full TUI framework
- replacing `fzf`
- managing secrets or credentials directly
- supporting complex multi-step workflows in the initial version

## Functional Requirements

### Popup and Binding

- The plugin must register one or more tmux key bindings.
- A key binding must open a tmux popup using `display-popup`.
- Popup size should be configurable through tmux options.

### Search Flow

- The popup must run an `fzf`-based search flow.
- The search flow must support arbitrary input data.
- The template must support at least these data sources:
  - output from a CLI command
  - file contents
  - cached data

### Data Pipeline

The template should model one popup flow as:

`source -> transform -> fzf -> resolve -> action`

- `source`: fetch raw data
- `transform`: format raw data for display and selection
- `fzf`: provide interactive filtering and selection
- `resolve`: convert the selected row into the value needed by the action
- `action`: perform the final behavior

### Actions

The template must support at least these post-selection actions:

- copy selected value to clipboard
- send selected value to a tmux pane with `tmux send-keys`
- execute an arbitrary command with the selected value
- print the selected value to standard output

### Configuration

The template should allow core behavior to be configured through tmux options, including:

- key binding
- popup width and height
- `fzf` prompt
- default action
- cache enable/disable
- cache lifetime

### Error Handling

- Missing dependencies must be detected before the flow starts.
- Failures in source, transform, resolve, or action steps must be shown inside the popup.
- The user must be able to close the popup after an error without losing context immediately.

### Caching

- Cache usage must be optional.
- Cache data should be limited to the minimum information required for later steps.
- Cache writes should use safe file handling.

## Non-Functional Requirements

- The implementation should stay shell-based and lightweight.
- The default example should work with minimal configuration.
- The template should be portable across macOS, Linux, and WSL where practical.
- Clipboard handling should be abstracted behind a common helper.
- Core responsibilities should be separated clearly:
  - tmux integration
  - popup execution
  - dependency checks
  - data source handling
  - action execution

## Design Requirements

- The template core should act as a framework layer.
- Individual use cases should be added as profiles or adapters.
- A profile should be able to define:
  - how data is fetched
  - how rows are displayed in `fzf`
  - how a selection is resolved
  - what action runs after selection

## Initial Architecture Direction

A reasonable first structure is:

- `plugin/*.tmux`: tmux entrypoints and key bindings
- `scripts/core/*.sh`: shared helpers
- `scripts/profiles/*.sh`: per-use-case implementations

Core helpers will likely include:

- tmux option readers
- dependency checks
- popup runner
- `fzf` runner
- clipboard helpers
- cache helpers
- action helpers

## MVP Scope

The first implementation should be intentionally narrow:

- support a single profile
- support CLI output as the source
- support these actions:
  - clipboard
  - send-keys
  - stdout
- defer cache if it adds too much complexity
- defer advanced preview customization
- defer multi-step flows

## Open Questions

- How should a profile be declared: shell function set, config file, or executable hooks?
- Should `transform` and `resolve` be separate hooks, or should a profile return a structured row format?
- Should action selection be global, per profile, or both?
- How much of `fzf` should be exposed directly as configuration?
