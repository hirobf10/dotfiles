---
name: herdr-orchestration
description: "herdr 上で複数エージェントを束ねてタスクを進めるための個人規約。ユーザーが herdr でのリード役・実装/レビューの子セッションへの委譲・リポジトリや worktree ワークスペースの運用管理を頼んだときに、公式 herdr スキルと併せて読む。命名規則と後片付けの手順も含む。"
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

## 子セッションは auto mode で起動する

委譲した実装役・レビュー役は、逐一の許可待ちで止まらないよう **auto mode 相当で起動する**
(親が `agent prompt --wait` で待っている間、子が確認待ちで固まるのを防ぐ)。

渡し方は `agent start` の `--` 以降にネイティブ引数を置く:

- claude: `-- --permission-mode auto --model claude-fable-5 --effort xhigh`
  (`--model` は `fable` などの alias も可)
- codex: `-- -a on-request -s workspace-write -m gpt-5.6-sol -c model_reasoning_effort=high`
  (`-a on-request` = 必要時のみ確認、`-s workspace-write` = worktree 内は書き込み可)
- 上記以外の kind は、そのエージェントの `--help` で auto 相当の指定方法を確認してから起動する

**許可を完全にスキップするフラグは使わない**(claude の `--dangerously-skip-permissions`、
codex の `--dangerously-bypass-approvals-and-sandbox`)。auto mode は危険な操作では
ユーザーに上がってくるので、その挙動を保つ。子が `blocked` で止まったら親が
`agent get` / `agent read` で状況を確認し、判断が必要ならユーザーに上げる。

実装とレビューを別種のエージェントにするとクロスチェックになる(推奨。強制ではない)。

## ワークスペース構成

- **親(リード)ワークスペースはタスク単位**。ラベルはタスク名そのまま。cwd は複数リポジトリ
  横断なら ghq root(`ghq root`)、単一リポジトリなら その repo
- **1 リポジトリ = 1 ワークスペース**(ラベル = repo 名)。使い捨てで、終わったら閉じる
- **子セッションは worktree ワークスペース**。変更対象リポジトリ配下に作る

## 中間生成物の置き場

`~/.claude/orchestration/<task-slug>/` に `plan.md` / `review-<n>.md` などを置く。
`~/.claude` は Claude セッションの許可済みディレクトリなので子セッションから読める。
**リポジトリ内には置かない**(コミットに混ざる)。後片付けでディレクトリごと削除する。

## 命名規則

herdr 側が自動で見せる情報を重複させないのが基準:

- サイドバーの space 行は **branch と git_status を自動表示**する → ラベルにブランチ名を
  入れない
- ペイン境界は `show_agent_labels_on_pane_borders = false` なので、**名前を付けないと
  何も出ない** → 分割したペインには必ず役割名を付ける

| 対象 | 命名 | 例 |
| --- | --- | --- |
| 親(リード)ワークスペース | `<タスク>` | `キャッシュ層の追加` |
| リポジトリワークスペース | repo 名(ghq ピッカーの既定) | `example-api` |
| 子(worktree)ワークスペース | `<repo>: <タスク>` | `example-api: キャッシュ層の追加` |
| タブ | 既定の番号のまま。付け直さない | `1` |
| ペイン | 役割名 | `impl` / `review` |
| エージェント名(CLI ターゲット) | `<task-slug>-<役割>` | `cache-layer-impl` |

- ペイン名は `herdr pane rename <pane_id> <役割>` で、**エージェント起動直後に必ず付ける**。
  どちらが実装でどちらがレビューか画面で判別できるようにするため
- エージェント名は **live agent 全体で一意**でなければならない(herdr の制約)。並行タスクで
  衝突しないよう task slug を前置し、`[a-z][a-z0-9_-]{0,31}` に収める
- task slug は中間生成物ディレクトリ `~/.claude/orchestration/<task-slug>/` と揃える

## オーケストレーションの流れ

### 1. 親セッションでプランを立てる

親セッションは自分。プランを立ててユーザーと擦り合わせ、**承認されるまで実装に入らない**。

### 2. 実装を子セッションに委譲する

1. 必要に応じて issue を作成する(`gh issue create`。作成の可否はユーザーに確認)
2. プランのボリュームが大きい場合は `plan.md` に書き出し、子セッションが読める状態にする
3. 変更対象リポジトリで worktree ワークスペースを作る(base は fetch 後の `origin/main`):
   `herdr worktree create --cwd <repoパス> --branch <名前> --base origin/main --label "<repo>: <タスク>" --no-focus`
   → `root_pane` の pane_id が返る(worktree の置き場は `~/.herdr/worktrees/<repo>/<branch>`)
4. その pane に実装エージェントを起動(種別・モデルはユーザー指定):
   `herdr agent start <slug>-impl --kind <kind> --pane <pane_id> -- <モデル引数>`
5. ペインに役割名を付ける: `herdr pane rename <pane_id> impl`
6. `herdr agent prompt <slug>-impl "<指示 / plan.md の絶対パス / issue 番号>" --wait --timeout <ms>`

指示に**必ず含める**こと:

- **コミットしない**(git 履歴を書くのは親だけ。`git add` / `git commit` / `git push` /
  PR 作成はいずれも行わない)。変更は worktree の作業ツリーに置いたままにする
- **lint / test を全体実行して通してから報告する**(ユーザーの規約どおり、編集の度ではなく
  最後にまとめて。親は編集しないので、ここで通しておかないと往復が増える)
- 何をどう変えたか、lint / test の結果を添えて報告する

### 3. レビューを別の子セッションに委譲する

**実装と同じ worktree ワークスペース内に、別ペインを作って行う。**
レビュー用に別ワークスペースは作らない。理由は、実装とレビューが並んで見えて
**画面上で状況を把握しやすい**こと、同じ worktree の差分を見る必要があること、
1 タスク = 1 ワークスペースに保つと後片付けも 1 回で済むこと:

1. 実装ペインを分割する:
   `herdr pane split --pane <impl_pane_id> --direction down --cwd <worktreeパス> --no-focus`
2. `herdr agent start <slug>-review --kind <kind> --pane <新pane_id> -- <モデル引数>`
3. ペインに役割名を付ける: `herdr pane rename <新pane_id> review`
4. 差分の見方、`plan.md`、issue を渡す。指摘は `review-<n>.md` に書かせてパスだけ受け取る

**差分はコミット前の作業ツリーを見る**(コミットは通過後に親が行うため、`origin/main...HEAD`
では何も出ない):

- `git status --short` … 変更ファイルの一覧
- `git diff origin/main` … 変更内容(追跡済みファイル)
- `??` の**新規ファイルは diff に出ない**ので、レビュー役に直接読ませる

lint / test は実装役が通している前提。**レビュー役に実際に走らせて確認させる**(親は実行しない)。
落ちていれば指摘に含めさせる。

実装ペインとレビューペインは**どちらも生かしたまま**次の往復に使う。

### 4. 修正 ↔ レビューを繰り返す

対応すべき指摘が出たら、生きている実装エージェントに投げ返す:
`herdr agent prompt <slug>-impl "<review-<n>.md の絶対パス> を読んで対応する。コミットはしない" --wait`
→ 再レビュー。**レビュー通過まで繰り返す**。

ただし**ループ上限を決めて**(3 往復程度)、超えたら自分で判断せずユーザーに状況を報告する。

### 5. コミットして PR を作成する(親が行う)

**レビュー通過後に初めてコミットする。** git 履歴を書くのは親だけで、子セッションには
やらせない:

1. worktree で内容を確認し(`git status --short` / `git diff origin/main`)、
   **変更の性質ごとにコミットを分ける**(ユーザーの作業フロー規約)
2. push して PR を作成する。issue があればリンクする

lint / test は実装役とレビュー役で済んでいるので、親では実行しない。
push / PR 作成はユーザー設定で確認が入る。

### 6. 後片付け

PR がマージされるなどタスクが完了したら:

1. `herdr worktree remove --workspace <ID>` → **ブランチは残る**ので不要なら `git branch -d`。
   タスクを中断した場合は作業ツリーが未コミットのまま残るので、破棄してよいことを
   ユーザーに確認した上で `--force` を付ける
2. `~/.claude/orchestration/<task-slug>/` を削除
3. 親ワークスペースを閉じる(ユーザーに確認)

## リードの役割

- リードは「読む・調整する・委譲する」。**配下リポジトリのファイルを直接編集しない**
  (親ディレクトリ起動では各 repo の CLAUDE.md がコンテキストに載らないため)
- 編集・実装は各 repo / worktree ワークスペースの子セッションに委譲する
- 例外: **git 履歴を書くのは親だけ**。コミット・push・PR 作成は親が行う(ファイル編集ではない)

## 受け渡しと後始末

- 複雑な成果物の受け渡しはターミナル読み取りではなく**ファイル経由**(相手に md を書かせて
  パスだけ受け取る)
- `agent read` / `pane read` の本文は JSON の `result.read.text`
- 自分が作ったワークスペース・worktree・ペイン・中間生成物は自分で畳む。
  **ユーザーが作ったものは明示的に頼まれない限り閉じない**
