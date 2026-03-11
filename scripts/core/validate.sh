#!/usr/bin/env bash

require_command() {
  local name="$1"

  if ! command -v "$name" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$name" >&2
    return 1
  fi
}

validate_core_dependencies() {
  require_command tmux
  require_command fzf
}

validate_action_dependencies() {
  local action="$1"

  case "$action" in
    stdout|send-keys)
      return 0
      ;;
    clipboard)
      if command -v pbcopy >/dev/null 2>&1 || command -v xclip >/dev/null 2>&1 || command -v clip.exe >/dev/null 2>&1; then
        return 0
      fi

      echo "Clipboard action requires one of: pbcopy, xclip, clip.exe" >&2
      return 1
      ;;
    *)
      printf 'Unsupported action: %s\n' "$action" >&2
      return 1
      ;;
  esac
}

validate_profile_dependencies() {
  if has_function profile_check_dependencies; then
    profile_check_dependencies
  fi
}
