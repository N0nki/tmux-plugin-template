#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$CURRENT_DIR/scripts/core/tmux_options.sh"

key="$(get_popup_template_option "@popup-template-key" "u")"
profile="$(get_popup_template_option "@popup-template-profile" "example")"
popup_width="$(get_popup_template_option "@popup-template-popup-width" "80%")"
popup_height="$(get_popup_template_option "@popup-template-popup-height" "60%")"

if [ -n "$key" ]; then
  tmux bind-key "$key" \
    display-popup -E -w "$popup_width" -h "$popup_height" \
    "$CURRENT_DIR/scripts/run.sh --profile '$profile' --target-pane '#{pane_id}'"
fi
