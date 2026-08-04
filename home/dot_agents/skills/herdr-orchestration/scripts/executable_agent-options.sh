#!/bin/sh
# 子セッションに起動できるエージェントの選択肢を集める。
# 実装役/レビュー役をユーザーに尋ねる前に実行し、この出力を選択肢の根拠にする。
# モデル名を列挙する CLI は claude/codex とも存在しないので、既定値と alias を示して
# 自由入力も受け付ける前提で使う。
set -u

printf '## herdr が起動できる kind\n'
herdr agent start --help 2>&1 | sed -n 's/.*\[possible values: //p' | tr -d ']' | sed 's/^/  /'

printf '\n## claude\n'
if command -v claude >/dev/null 2>&1; then
    printf '  effort 候補: '
    claude --help 2>&1 | grep -A1 -- '--effort <level>' | tr -s ' \n' ' ' \
        | sed -n 's/.*(\([a-z, ]*\)).*/\1/p' | sed 's/[[:space:]]*$//'
    printf '\n'
    printf '  model: alias(fable / opus / sonnet)または完全名(claude-fable-5 等)\n'
    m=$(grep -oE '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.claude/settings.json" 2>/dev/null \
        | head -1 | sed 's/.*"model"[[:space:]]*:[[:space:]]*"//;s/"$//')
    e=$(grep -oE '"effortLevel"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.claude/settings.json" 2>/dev/null \
        | head -1 | sed 's/.*"effortLevel"[[:space:]]*:[[:space:]]*"//;s/"$//')
    printf '  既定: model=%s effort=%s\n' "${m:-未設定(CLI 既定)}" "${e:-未設定}"
    printf '  渡し方: -- --model <model> --effort <level>\n'
else
    printf '  (未インストール)\n'
fi

printf '\n## codex\n'
if command -v codex >/dev/null 2>&1; then
    printf '  既定 (~/.codex/config.toml):\n'
    grep -E '^(model|model_reasoning_effort)' "$HOME/.codex/config.toml" 2>/dev/null | sed 's/^/    /'
    printf '  渡し方: -- -m <model> -c model_reasoning_effort=<level>\n'
else
    printf '  (未インストール)\n'
fi

printf '\n注: 上記以外の kind を選ぶ場合は、そのエージェントの --help でモデル/エフォートの\n'
printf '    指定方法を確認してから起動する。\n'
