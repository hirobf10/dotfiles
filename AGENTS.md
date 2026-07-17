# AGENTS.md

このリポジトリ（hirobf10/dotfiles）で作業する AI エージェント向けの編集ルール。

## リポジトリ構成

- [chezmoi](https://www.chezmoi.io/) で管理する dotfiles リポジトリ。`.chezmoiroot` により **`home/` 配下だけが適用対象のソース**。リポジトリ直下は README・CI・本ファイル等のメタ領域
- `home/dot_config/claude/` と `home/dot_config/codex/` は適用されないスタッシュ（`.chezmoiignore` で除外）。実行時パス（`~/.claude/*`、`~/.codex/AGENTS.md`）はここへの symlink として適用される
- symlink 経由の実ファイル編集はそのままソース編集になる（ドリフトしない）。コピー適用されるファイル（`.zshrc`、`.gitconfig` 等のテンプレート）は `chezmoi edit` で編集し、直接編集した場合は `chezmoi re-add` で取り込む

## 秘密・個人情報を載せない

- このリポジトリは **public**。認証トークン・API キー・パスワード、マシン固有の絶対パス、個人のディレクトリ構造やローカル trust 情報は含めない
- ファイルを管理対象へ加える前に必ず中身を確認する。該当情報がある場合は管理しない（必要なら環境変数参照やプレースホルダへ置き換える）

## Git 運用

- main 直コミットで運用。コミットは論理単位で分割する
- コミットメッセージは英語・命令形サマリ（例: `Manage Claude Code settings and hooks`）
- `run_once_setup.sh` を編集すると内容ハッシュが変わり、次回 `chezmoi apply` で再実行される（冪等に保つこと）
