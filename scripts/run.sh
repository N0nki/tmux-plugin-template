#!/usr/bin/env bash

set -eu

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CURRENT_DIR/scripts/core/tmux_options.sh"
source "$CURRENT_DIR/scripts/core/profile.sh"
source "$CURRENT_DIR/scripts/core/validate.sh"
source "$CURRENT_DIR/scripts/core/errors.sh"
source "$CURRENT_DIR/scripts/core/fzf.sh"
source "$CURRENT_DIR/scripts/core/clipboard.sh"
source "$CURRENT_DIR/scripts/core/actions.sh"

POPUP_TEMPLATE_PROFILE=""
TMUX_POPUP_TEMPLATE_TARGET_PANE=""

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        POPUP_TEMPLATE_PROFILE="${2:-}"
        shift 2
        ;;
      --target-pane)
        TMUX_POPUP_TEMPLATE_TARGET_PANE="${2:-}"
        shift 2
        ;;
      *)
        printf 'Unknown argument: %s\n' "$1" >&2
        return 1
        ;;
    esac
  done
}

run_stage_to_file() {
  local stage="$1"
  local output_file="$2"
  local error_file="$3"
  shift 3

  : >"$error_file"

  if ! "$@" >"$output_file" 2>"$error_file"; then
    render_stage_error "$stage" "$error_file"
    return 1
  fi
}

run_transform_stage() {
  local input_file="$1"
  local output_file="$2"
  local error_file="$3"

  : >"$error_file"

  if ! profile_transform <"$input_file" >"$output_file" 2>"$error_file"; then
    render_stage_error "profile_transform" "$error_file"
    return 1
  fi
}

main() {
  local source_file
  local rows_file
  local error_file
  local selection
  local resolved_value

  parse_args "$@"
  load_popup_template_runtime_options

  if [ -z "$POPUP_TEMPLATE_PROFILE" ]; then
    render_message_and_pause "Profile is required"
    exit 1
  fi

  source_file="$(mktemp)"
  rows_file="$(mktemp)"
  error_file="$(mktemp)"
  trap 'rm -f "$source_file" "$rows_file" "$error_file"' EXIT

  if ! validate_core_dependencies 2>"$error_file"; then
    render_stage_error "validate_core_dependencies" "$error_file"
    exit 1
  fi

  if ! load_profile "$CURRENT_DIR" "$POPUP_TEMPLATE_PROFILE" 2>"$error_file"; then
    render_stage_error "load_profile" "$error_file"
    exit 1
  fi

  if ! validate_profile_contract 2>"$error_file"; then
    render_stage_error "validate_profile_contract" "$error_file"
    exit 1
  fi

  if ! validate_profile_dependencies 2>"$error_file"; then
    render_stage_error "validate_profile_dependencies" "$error_file"
    exit 1
  fi

  if ! validate_action_dependencies "$POPUP_TEMPLATE_ACTION" 2>"$error_file"; then
    render_stage_error "validate_action_dependencies" "$error_file"
    exit 1
  fi

  if ! run_stage_to_file "profile_source" "$source_file" "$error_file" profile_source; then
    exit 1
  fi

  if ! run_transform_stage "$source_file" "$rows_file" "$error_file"; then
    exit 1
  fi

  if [ ! -s "$rows_file" ]; then
    render_message_and_pause "No items available"
    exit 0
  fi

  selection="$(run_fzf_selection "$rows_file" "$POPUP_TEMPLATE_PROMPT" || true)"

  if [ -z "$selection" ]; then
    exit 0
  fi

  if ! resolved_value="$(profile_resolve "$selection" 2>"$error_file")"; then
    render_stage_error "profile_resolve" "$error_file"
    exit 1
  fi

  if ! run_action "$POPUP_TEMPLATE_ACTION" "$resolved_value" 2>"$error_file"; then
    render_stage_error "action" "$error_file"
    exit 1
  fi

  if [ "$POPUP_TEMPLATE_ACTION" != "stdout" ]; then
    pause_before_close
  fi
}

main "$@"
