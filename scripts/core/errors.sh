#!/usr/bin/env bash

pause_before_close() {
  printf '\nPress any key to close...'
  read -r -n 1 _
}

render_stage_error() {
  local stage="$1"
  local error_file="$2"

  printf 'Error in %s\n' "$stage"

  if [ -s "$error_file" ]; then
    cat "$error_file"
  else
    echo "Unknown error"
  fi

  if has_function profile_on_error; then
    echo
    profile_on_error "$stage" || true
  fi

  pause_before_close
}

render_message_and_pause() {
  local message="$1"

  printf '%s\n' "$message"
  pause_before_close
}
