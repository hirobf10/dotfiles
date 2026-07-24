#!/bin/sh
# ghq のリポジトリを fzf で選び、herdr の新しいワークスペースとして開く(popup から起動)
set -u

dir="$(ghq list -p | fzf --height 100% --reverse --prompt='repo> ')" || exit 0
[ -n "$dir" ] || exit 0

exec "${HERDR_BIN_PATH:-herdr}" workspace create --cwd "$dir" --label "$(basename "$dir")" --focus
