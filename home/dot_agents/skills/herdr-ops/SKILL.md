---
name: herdr-ops
description: "herdr 上でのマルチエージェント運用の個人規約。ユーザーが herdr でのリード役・他エージェントへの作業委譲・リポジトリ/worktree ワークスペースの運用管理を頼んだときに、公式 herdr スキルと併せて読む。"
---

# herdr 運用規約(個人)

CLI の基本操作は公式 `herdr` スキルに従う。構文はインストール済みバイナリの help が正。
このスキルはその上に載る「この環境での運用ルール」を定める。

## ワークスペース構成

- **1 リポジトリ = 1 ワークスペース**(ラベル = repo 名)。使い捨て運用で、タスクが終わったら閉じる
- **同一 repo の並行タスク**は worktree ワークスペースに分離する
- **複数リポジトリ横断タスク**は ghq root(`ghq root` で取得)直下にタスク単位のリード用ワークスペース(ラベル `lead: <タスク>`)を作る

## リードの役割

- リードは「読む・調整する・委譲する」。**配下リポジトリのファイルを直接編集しない**(親ディレクトリ起動では各 repo の CLAUDE.md がコンテキストに載らないため)
- 編集・実装は各 repo / worktree ワークスペースのエージェントに委譲する

## エージェントの役割分担

- 役割(リード・実装・レビュー等)とエージェント種別(claude / codex / …)の組み合わせは**固定しない**。ユーザーの指定があればそれに従い、なければ確認するか claude を既定とする
- レビュー役を実装役と別種のエージェントにするクロスチェックは有効な選択肢(強制ではない)

## worktree ワークスペースのライフサイクル

1. ベースは fetch 後の `origin/main` を基本とする(ユーザーの作業フロー規約)
2. `herdr worktree create --cwd <repoパス> --branch <名前> --base <REF> --no-focus --json` → worktree + ワークスペースが生成され `root_pane` が返る(置き場: `~/.herdr/worktrees/<repo>/<branch>`)
3. `herdr agent start <名前> --workspace <ID> -- <agentコマンド>` で起動し、`agent send` → `agent wait --status idle` で完了を待つ(新しい herdr では `agent prompt --wait` 等に置き換わっている場合がある。help を確認)
4. 完了後 `herdr worktree remove --workspace <ID>`。**ブランチは残る**ので、破棄タスクなら別途 `git branch -d`

## 受け渡しと後始末

- 複雑な成果物の受け渡しはターミナル読み取りではなく**ファイル経由**(相手に md を書かせてパスだけ受け取る)
- `agent read` / `pane read` の本文は JSON の `result.read.text`
- 自分が作ったワークスペース・worktree・ペインは自分で畳む。**ユーザーが作ったものは明示的に頼まれない限り閉じない**
