#!/usr/bin/env bash

profile_check_dependencies() {
  command -v tmux >/dev/null 2>&1 || {
    echo "Example profile requires tmux" >&2
    return 1
  }
}

profile_source() {
  tmux list-sessions -F '#S\t#{session_windows} windows\t#S'
}

profile_transform() {
  cat
}

profile_resolve() {
  local selected="$1"

  printf '%s\n' "$selected" | awk -F'\t' '{print $3}'
}

profile_on_error() {
  local stage="$1"

  if [ "$stage" = "profile_source" ]; then
    echo "Start at least one tmux session before using the example profile."
  fi
}
