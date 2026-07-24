#!/bin/sh
# タスク名を聞いて ghq root 直下にリード用ワークスペースを作る(popup から起動)
set -u

printf 'task> '
read -r task || exit 0
[ -n "$task" ] || exit 0

exec "${HERDR_BIN_PATH:-herdr}" workspace create --cwd "$(ghq root)" --label "lead: $task" --focus
