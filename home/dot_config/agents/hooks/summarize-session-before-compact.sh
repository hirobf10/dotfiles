#!/bin/bash

# Read session context from stdin
input=$(cat)

date_dir=$(date +%Y/%m/%d)
log_date=$(date +%Y-%m-%d)
timestamp=$(date +%H%M%S)
log_dir="${CLAUDE_PROJECT_DIR}/.claude/logs/${date_dir}"
mkdir -p "$log_dir"
output_file="$log_dir/${timestamp}.md"

# transcript_path を取得
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
  exit 0
fi

# transcript から会話内容を抽出
transcript=$(jq -r '
  select(.type == "user" or .type == "assistant") |
  "\(.type): \(.message.content | if type == "array" then map(select(.type == "text") | .text) | join("") else . end)"
' "$transcript_path" 2>/dev/null | tail -c 50000)

# claude -p で作業ログを生成（失敗しても compaction はキャンセルしない）
claude -p "以下の会話トランスクリプトをもとに、作業ログを日本語で作成してください。
ファイルには書き込まず、マークダウン形式でそのまま出力してください。
該当しないセクションは空のままにしてください。
前回のコンパクト時の要約や引き継ぎ情報は除外し、このセッションで実際に行った作業のみを記載してください。
また、以下のマークダウン形式に必ず従い、不要な情報は出力しないでください。

# 作業ログ - ${log_date}-${timestamp}

## やったこと

## 決定事項

## 捨てた選択肢と理由

## ハマりどころ

## 学び

## 次にやること

## 関連ファイル

---
会話トランスクリプト:
${transcript}" > "$output_file" 2>/dev/null || rm -f "$output_file"

exit 0
