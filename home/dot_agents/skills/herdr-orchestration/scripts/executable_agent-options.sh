#!/bin/sh
# 子セッションに起動できるエージェントの選択肢を集める。
# 実装役/レビュー役をユーザーに尋ねる前に実行し、この出力を選択肢の根拠にする。
# モデル名を列挙する CLI は claude/codex とも存在しないので、既定値と alias を示して
# 自由入力も受け付ける前提で使う。
set -u

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cfg="$here/../agents.toml"

printf '## 既定 (agents.toml — ユーザーに尋ねるときの既定候補)\n'
if [ ! -f "$cfg" ]; then
    printf '  (agents.toml が無い)\n'
elif ! command -v python3 >/dev/null 2>&1; then
    printf '  (python3 が無いので未解析。%s を直接読む)\n' "$cfg"
elif ! CFG="$cfg" python3 - <<'PY'
import os, sys, tomllib

try:
    with open(os.environ["CFG"], "rb") as fh:
        conf = tomllib.load(fh)
except (OSError, tomllib.TOMLDecodeError) as err:
    print(f"  (読めない: {err})")
    sys.exit(1)

for role in ("impl", "review"):
    r = conf.get(role) or {}
    fields = " ".join(f"{k}={r.get(k) or '(CLI 既定)'}" for k in ("kind", "model", "effort"))
    print(f"  {role:<7}{fields}")
PY
then
    printf '  (agents.toml の解析に失敗)\n'
fi

printf '\n## herdr が起動できる kind\n'
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
    printf '  CLI 側の既定: model=%s effort=%s\n' "${m:-未設定(CLI 既定)}" "${e:-未設定}"
    printf '  渡し方: -- --model <model> --effort <level>\n'
else
    printf '  (未インストール)\n'
fi

printf '\n## codex\n'
if command -v codex >/dev/null 2>&1; then
    printf '  CLI 側の既定 (~/.codex/config.toml):\n'
    grep -E '^(model|model_reasoning_effort)' "$HOME/.codex/config.toml" 2>/dev/null | sed 's/^/    /'
    printf '  渡し方: -- -m <model> -c model_reasoning_effort=<level>\n'
else
    printf '  (未インストール)\n'
fi

printf '\n注: 上記以外の kind を選ぶ場合は、そのエージェントの --help でモデル/エフォートの\n'
printf '    指定方法を確認してから起動する。\n'
