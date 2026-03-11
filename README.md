# tmux-plugin-template

Template for tmux plugins that use `display-popup` and `fzf` to search arbitrary data and run an action on the selected result.

## Status

This repository currently contains an MVP implementation with:

- a tmux popup entrypoint
- a shared `source -> transform -> fzf -> resolve -> action` flow
- built-in actions: `stdout`, `clipboard`, `send-keys`
- one example profile based on `tmux list-sessions`

## Structure

```text
plugin/tmux-plugin-template.tmux
scripts/run.sh
scripts/core/*.sh
scripts/profiles/example.sh
doc/
```

## Installation

Add this plugin to your tmux config and source it.

```tmux
run-shell /path/to/tmux-plugin-template/plugin/tmux-plugin-template.tmux
```

Reload tmux:

```sh
tmux source-file ~/.tmux.conf
```

## Minimal Configuration

```tmux
set -g @popup-template-key 'u'
set -g @popup-template-profile 'example'
set -g @popup-template-popup-width '80%'
set -g @popup-template-popup-height '60%'
set -g @popup-template-prompt 'Session > '
set -g @popup-template-action 'stdout'
set -g @popup-template-auto-clear-seconds '30'

run-shell /path/to/tmux-plugin-template/plugin/tmux-plugin-template.tmux
```

Press `prefix + u` to open the popup.

## tmux Options

| Option | Default | Description |
| --- | --- | --- |
| `@popup-template-key` | `u` | Key binding used to open the popup |
| `@popup-template-profile` | `example` | Profile name to load |
| `@popup-template-popup-width` | `80%` | Popup width |
| `@popup-template-popup-height` | `60%` | Popup height |
| `@popup-template-prompt` | `Select > ` | `fzf` prompt |
| `@popup-template-action` | `stdout` | One of `stdout`, `clipboard`, `send-keys` |
| `@popup-template-auto-clear-seconds` | `30` | Clipboard auto-clear timeout |

## Example Profile

The bundled `example` profile lists tmux sessions and resolves the selected session name.

- `stdout`: prints the selected session name
- `clipboard`: copies the selected session name
- `send-keys`: sends the selected session name back to the pane that opened the popup

## Writing a Profile

Profiles live under `scripts/profiles/` and must define:

- `profile_source`
- `profile_transform`
- `profile_resolve`

Profiles may optionally define:

- `profile_check_dependencies`
- `profile_action`
- `profile_on_error`

## Notes

- `send-keys` targets the pane that opened the popup, not the popup pane itself.
- `send-keys` can deliver text to the wrong prompt if you invoke it in the wrong pane.
- `profile_preview`, `command` action, and cache support are intentionally deferred from the MVP.
