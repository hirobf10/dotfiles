# dotfiles 管理（chezmoi）

`~/.local/share/chezmoi`（リポジトリ hirobf10/dotfiles、public）で管理。`.chezmoiroot` により適用対象ソースは `home/` 配下。

## 編集方法

ファイルにより2方式ある：

- **symlink 管理**（`~/.claude/CLAUDE.md`・`settings.json`・`hooks/`・`rules/`、`~/.codex/AGENTS.md`）: 実体はソースの `home/dot_config/{agents,claude,codex}/` にあり、実ファイルはそこへの symlink。**直接編集してよい**（編集＝ソース編集でドリフトしない）。編集後はソースリポジトリでコミット・push する
- `~/.claude/CLAUDE.md` と `~/.codex/AGENTS.md` は**同一の共有ファイル** `home/dot_config/agents/AGENTS.md` を指す。内容はツール中立に書く。Claude 固有の指示は `~/.claude/rules/` へ
- **コピー/テンプレート管理**（`.zshrc`・`.gitconfig`・`.gitexclude`・`.zprofile`・`Brewfile` 等）: `chezmoi edit <target>` でソースを編集し `chezmoi apply`。実ファイルを直接編集した場合は `chezmoi re-add <target>` で取り込む

注意: `~/.claude/settings.json` が symlink でなく通常ファイルになっていたら、何らかのツールが symlink を置換した状態。内容をソースへ反映してから `chezmoi apply` で symlink に戻す。

## 秘密・個人情報を載せない

- リポジトリは **public**。以下は管理対象に含めない：
  - 認証トークン・API キー・パスワード等の秘密情報
  - マシン固有の絶対パス、個人のディレクトリ構造、ローカルの trust 情報など環境依存・個人情報にあたる内容
  - 社内プロジェクトのコードネーム・社内システム名・組織固有の情報（コメントや説明文への記載も不可）
- 新たにファイルを管理下へ加える前に必ず中身を確認する。上記が含まれる場合は管理しない（必要なら環境変数参照やプレースホルダに置き換える）
