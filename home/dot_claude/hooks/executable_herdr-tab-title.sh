#!/bin/sh
# UserPromptSubmit フック: プロンプト先頭を herdr のタブ名に反映する
set -u

# フック入力(JSON)は stdin で来る。ヒアドキュメントと競合するので先にファイルへ退避
hook_input_file="$(mktemp)" || exit 0
trap 'rm -f "$hook_input_file"' EXIT
cat >"$hook_input_file" 2>/dev/null || true

[ "${HERDR_ENV:-}" = "1" ] || exit 0   # herdr のペイン内でだけ動かす
command -v herdr >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

HOOK_INPUT_FILE="$hook_input_file" python3 - <<'PY' >/dev/null 2>&1
import json, os, subprocess, sys

with open(os.environ["HOOK_INPUT_FILE"], encoding="utf-8") as fh:
    d = json.load(fh)
if d.get("agent_id"):  # サブエージェントのイベントは無視
    sys.exit(0)

prompt = " ".join(str(d.get("prompt") or "").split())
if not prompt:
    sys.exit(0)
title = prompt[:19] + "…" if len(prompt) > 20 else prompt
session_id = str(d.get("session_id") or "")

out = subprocess.run(["herdr", "api", "snapshot"],
                     capture_output=True, text=True, timeout=3).stdout
snap = json.loads(out)["result"]["snapshot"]
agents = snap.get("agents") or []

# (1) セッションIDが herdr に登録済みなら、そのタブ
target = next((a["tab_id"] for a in agents
               if (a.get("agent_session") or {}).get("value") == session_id), None)

# (2) フォーカス中のペインが「セッション未登録の claude」なら、そのタブ
if target is None:
    fp = snap.get("focused_pane_id")
    target = next((a["tab_id"] for a in agents
                   if a.get("pane_id") == fp and a.get("agent") == "claude"
                   and not (a.get("agent_session") or {}).get("value")), None)

# (3) どちらでもなければ何もしない
if target:
    subprocess.run(["herdr", "tab", "rename", target, title],
                   capture_output=True, timeout=3)
PY
exit 0
