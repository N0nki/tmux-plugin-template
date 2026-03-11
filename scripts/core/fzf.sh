#!/usr/bin/env bash

run_fzf_selection() {
  local input_file="$1"
  local prompt="${2:-Select > }"

  fzf \
    --layout=reverse \
    --border \
    --delimiter=$'\t' \
    --with-nth=1,2 \
    --prompt="$prompt" \
    <"$input_file"
}
