#!/usr/bin/env bash

get_popup_template_option() {
  local option="$1"
  local default="$2"
  local value

  value="$(tmux show-option -gqv "$option")"
  echo "${value:-$default}"
}

load_popup_template_runtime_options() {
  POPUP_TEMPLATE_PROFILE="${POPUP_TEMPLATE_PROFILE:-$(get_popup_template_option "@popup-template-profile" "example")}"
  POPUP_TEMPLATE_PROMPT="$(get_popup_template_option "@popup-template-prompt" "Select > ")"
  POPUP_TEMPLATE_ACTION="$(get_popup_template_option "@popup-template-action" "stdout")"
  POPUP_TEMPLATE_AUTO_CLEAR_SECONDS="$(get_popup_template_option "@popup-template-auto-clear-seconds" "30")"
}
