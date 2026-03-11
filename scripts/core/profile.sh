#!/usr/bin/env bash

has_function() {
  local name="$1"
  declare -F "$name" >/dev/null 2>&1
}

validate_profile_name() {
  local name="$1"

  case "$name" in
    ''|*[!A-Za-z0-9_-]*)
      printf 'Invalid profile name: %s\n' "$name" >&2
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

load_profile() {
  local root_dir="$1"
  local profile_name="$2"
  local profile_file

  validate_profile_name "$profile_name" || return 1

  profile_file="$root_dir/scripts/profiles/${profile_name}.sh"

  if [ ! -f "$profile_file" ]; then
    printf 'Profile not found: %s\n' "$profile_file" >&2
    return 1
  fi

  # shellcheck source=/dev/null
  source "$profile_file"
}

validate_profile_contract() {
  local missing=0

  if ! has_function profile_source; then
    echo "Profile must define profile_source" >&2
    missing=1
  fi

  if ! has_function profile_transform; then
    echo "Profile must define profile_transform" >&2
    missing=1
  fi

  if ! has_function profile_resolve; then
    echo "Profile must define profile_resolve" >&2
    missing=1
  fi

  [ "$missing" -eq 0 ]
}
