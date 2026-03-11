#!/usr/bin/env bash

copy_to_clipboard() {
  local value="$1"

  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$value" | pbcopy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$value" | xclip -selection clipboard
  elif command -v clip.exe >/dev/null 2>&1; then
    printf '%s' "$value" | clip.exe
  else
    echo "No clipboard command available" >&2
    return 1
  fi
}

clear_clipboard() {
  if command -v pbcopy >/dev/null 2>&1; then
    printf '' | pbcopy
  elif command -v xclip >/dev/null 2>&1; then
    printf '' | xclip -selection clipboard
  elif command -v clip.exe >/dev/null 2>&1; then
    printf '' | clip.exe
  fi
}

schedule_clipboard_clear() {
  local seconds="$1"

  if [ "$seconds" -gt 0 ] 2>/dev/null; then
    (sleep "$seconds" && clear_clipboard >/dev/null 2>&1) &
  fi
}
