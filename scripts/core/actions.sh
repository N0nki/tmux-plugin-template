#!/usr/bin/env bash

run_action() {
  local action="$1"
  local value="$2"

  if has_function profile_action; then
    profile_action "$value"
    return $?
  fi

  case "$action" in
    stdout)
      printf '%s\n' "$value"
      ;;
    clipboard)
      copy_to_clipboard "$value"
      schedule_clipboard_clear "$POPUP_TEMPLATE_AUTO_CLEAR_SECONDS"
      printf 'Copied to clipboard (auto-clear in %ss)\n' "$POPUP_TEMPLATE_AUTO_CLEAR_SECONDS"
      ;;
    send-keys)
      if [ -z "${TMUX_POPUP_TEMPLATE_TARGET_PANE:-}" ]; then
        echo "Target pane is not set" >&2
        return 1
      fi

      tmux send-keys -t "$TMUX_POPUP_TEMPLATE_TARGET_PANE" "$value"
      printf 'Sent to pane %s\n' "$TMUX_POPUP_TEMPLATE_TARGET_PANE"
      ;;
    *)
      printf 'Unsupported action: %s\n' "$action" >&2
      return 1
      ;;
  esac
}
