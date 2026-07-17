# Dotfiles

chezmoiを使用したdotfiles管理リポジトリ

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

## 管理ファイル

### シェル・Git
- `.zshrc` - Zsh設定
- `.zprofile` - Homebrew初期化
- `.gitconfig` - Git設定
- `.gitexclude` - グローバル git 除外

### AI ツール
- `.claude/CLAUDE.md` - 開発設定
- `.claude/settings.json` - Claude Code 設定（権限・フック・プラグイン）
- `.claude/hooks/` - Claude Code フック
- `.claude/skills/` - スキル（`.agents/skills` への symlink）
- `.agents/skills/` - AI ツール共有スキルの実体
- `.codex/AGENTS.md`, `.codex/config.toml` - Codex 設定

### エディタ
- `Library/Application Support/Code/User/settings.json`, `keybindings.json` - VSCode 設定