---
name: herdr-ops
description: "herdr 上でのマルチエージェント運用の個人規約。ユーザーが herdr でのリード役・実装/レビューの子セッションへの委譲・リポジトリや worktree ワークスペースの運用管理を頼んだときに、公式 herdr スキルと併せて読む。"
---

# herdr 運用規約(個人)

CLI の基本操作は公式 `herdr` スキルに従う。構文はインストール済みバイナリの help が正。
このスキルはその上に載る「この環境での運用ルール」を定める。

## まず規模を判断する

**軽微なタスクは委譲しない。** 単一ファイルの小修正、調査、質問への回答、設定変更程度は
自分のセッション内で完結させる。以下のオーケストレーションは「プランをユーザーと擦り合わせる
価値がある規模」から適用する。判断に迷う規模ならユーザーに確認する。

## 実装役・レビュー役のエージェントはユーザー入力

子セッションで起動する**エージェント種別・モデル・エフォートは毎回ユーザーに確認する**
(依頼に指定があればそれに従う)。勝手に決めない。

**尋ねる前に選択肢を集める。** このスキル同梱のスクリプトを実行し、その出力を選択肢の
根拠にする(推測で選択肢を並べない):

```bash
sh <skill-dir>/scripts/agent-options.sh
```

出力に含まれるもの: herdr が起動できる kind の一覧、claude の effort 候補、claude/codex の
現在の既定モデルとエフォート、`--` 以降の渡し方。

**モデル名を列挙する CLI は claude/codex とも無い**ので、既定値と alias を選択肢として示し、
ユーザーの自由入力も受け付ける(Claude Code なら AskUserQuestion の Other が使える)。

渡し方は `agent start` の `--` 以降にネイティブ引数を置く:

- claude: `-- --model claude-fable-5 --effort xhigh`(`fable` などの alias も可)
- codex: `-- -m gpt-5.6-sol -c model_reasoning_effort=high`
- 上記以外の kind は、そのエージェントの `--help` で指定方法を確認してから起動する

実装とレビューを別種のエージェントにするとクロスチェックになる(推奨。強制ではない)。

## ワークスペース構成

- **親(リード)ワークスペースはタスク単位**。ラベルは `lead: <タスク>`。cwd は複数リポジトリ
  横断なら ghq root(`ghq root`)、単一リポジトリなら その repo
- **1 リポジトリ = 1 ワークスペース**(ラベル = repo 名)。使い捨てで、終わったら閉じる
- **子セッションは worktree ワークスペース**。変更対象リポジトリ配下に作る

## 中間生成物の置き場

`~/.claude/orchestration/<task-slug>/` に `plan.md` / `review-<n>.md` などを置く。
`~/.claude` は Claude セッションの許可済みディレクトリなので子セッションから読める。
**リポジトリ内には置かない**(コミットに混ざる)。後片付けでディレクトリごと削除する。

## オーケストレーションの流れ

### 1. 親セッションでプランを立てる

親セッションは自分。プランを立ててユーザーと擦り合わせ、**承認されるまで実装に入らない**。

### 2. 実装を子セッションに委譲する

1. 必要に応じて issue を作成する(`gh issue create`。作成の可否はユーザーに確認)
2. プランのボリュームが大きい場合は `plan.md` に書き出し、子セッションが読める状態にする
3. 変更対象リポジトリで worktree ワークスペースを作る(base は fetch 後の `origin/main`):
   `herdr worktree create --cwd <repoパス> --branch <名前> --base origin/main --label "<task>: impl" --no-focus`
   → `root_pane` の pane_id が返る(worktree の置き場は `~/.herdr/worktrees/<repo>/<branch>`)
4. その pane に実装エージェントを起動(種別・モデルはユーザー指定):
   `herdr agent start impl --kind <kind> --pane <pane_id> -- <モデル引数>`
5. `herdr agent prompt impl "<指示 / plan.md の絶対パス / issue 番号>" --wait --timeout <ms>`

指示に**必ず含める**こと: **コミットまで行い、push と PR 作成はしない**。

### 3. レビューを別の子セッションに委譲する

実装セッションとは**別のペイン**で行う(同じ worktree を見る必要があるので、実装ペインを
分割するのが基本):

1. `herdr pane split --pane <impl_pane_id> --direction down --cwd <worktreeパス> --no-focus`
2. `herdr agent start reviewer --kind <kind> --pane <新pane_id> -- <モデル引数>`
3. 差分の見方(`git diff origin/main...HEAD`)、`plan.md`、issue を渡す。指摘は
   `review-<n>.md` に書かせてパスだけ受け取る

### 4. 修正 ↔ レビューを繰り返す

対応すべき指摘が出たら、生きている実装エージェントに投げ返す:
`herdr agent prompt impl "<review-<n>.md の絶対パス> を読んで対応し、コミットまで行う" --wait`
→ 再レビュー。**レビュー通過まで繰り返す**。

ただし**ループ上限を決めて**(3 往復程度)、超えたら自分で判断せずユーザーに状況を報告する。

### 5. PR を作成する(親が行う)

レビュー通過後、親が push と PR 作成を行う(子セッションにはやらせない)。
issue があればリンクする。push / PR 作成はユーザー設定で確認が入る。

### 6. 後片付け

PR がマージされるなどタスクが完了したら:

1. `herdr worktree remove --workspace <ID>` → **ブランチは残る**ので不要なら `git branch -d`
2. `~/.claude/orchestration/<task-slug>/` を削除
3. 親ワークスペースを閉じる(ユーザーに確認)

## リードの役割

- リードは「読む・調整する・委譲する」。**配下リポジトリのファイルを直接編集しない**
  (親ディレクトリ起動では各 repo の CLAUDE.md がコンテキストに載らないため)
- 編集・実装は各 repo / worktree ワークスペースの子セッションに委譲する
- 例外: push と PR 作成は親が行う(ファイル編集ではない)

## 受け渡しと後始末

- 複雑な成果物の受け渡しはターミナル読み取りではなく**ファイル経由**(相手に md を書かせて
  パスだけ受け取る)
- `agent read` / `pane read` の本文は JSON の `result.read.text`
- 自分が作ったワークスペース・worktree・ペイン・中間生成物は自分で畳む。
  **ユーザーが作ったものは明示的に頼まれない限り閉じない**
