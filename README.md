# Dotfiles

chezmoiを使用したdotfiles管理リポジトリ

> **注意**: このリポジトリは public です。認証トークン・API キー等の秘密情報や、マシン固有の絶対パス・ローカルの trust 情報などの個人環境情報は含めないでください。新たにファイルを管理対象へ加える際は中身を確認すること。

## 前提条件

新しいMacの場合、最初にCommand Line Developer Toolsをインストール：
```bash
xcode-select --install
```

## クイックスタート

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply https://github.com/hirobf10/dotfiles.git
```

初回 init 時に Git の `name` / `email` をプロンプトで設定します。

## 開発環境セットアップ

初回の`chezmoi apply`時に自動的にセットアップスクリプトが実行されます。

自動インストール内容：
- Homebrew、Oh My Zsh
- anyenv（pyenv、nodenv、tfenv）
- Python 3.12、Node.js LTS、Terraform最新版
- VSCode拡張機能（`brew bundle`経由）
- その他開発ツール（詳細は`Brewfile`参照）

## 基本操作

```bash
chezmoi add ~/.dotfile       # ファイル追加
chezmoi diff                 # 差分確認
chezmoi apply                # 変更適用
chezmoi cd                   # ソースディレクトリへ移動
```

## リポジトリ構成

- `.chezmoiroot` により、適用対象のソースは `home/` 配下（リポジトリ直下は README・CI 等のメタ領域）
- `home/dot_config/{claude,codex}/` は適用されない実体置き場（`.chezmoiignore` で除外）。`~/.claude/*` と `~/.codex/AGENTS.md` はここへの **symlink** として適用されるため、実ファイルの編集がそのままソース編集になりドリフトしない

## 管理ファイル

### シェル・Git
- `.zshrc` - Zsh設定
- `.zprofile` - Homebrew初期化
- `.gitconfig` - Git設定
- `.gitexclude` - グローバル git 除外

### AI ツール（symlink 管理）
- `.claude/CLAUDE.md`, `.codex/AGENTS.md` - 開発設定（`dot_config/agents/AGENTS.md` を共有する同一ファイル）
- `.claude/settings.json` - Claude Code 設定（権限・フック・プラグイン）
- `.claude/hooks/` - Claude Code フック
- `.claude/rules/` - Claude Code ルール（Claude 固有の指示はこちら）