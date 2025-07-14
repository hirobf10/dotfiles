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

セットアップ後、gitの設定を更新してください：
```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

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

- `.gitconfig` - Git設定（環境別メール）
- `.zshrc` - Zsh設定
- `.zprofile` - Homebrew初期化
- `.claude/CLAUDE.md` - 開発設定
- `.npmrc` - npm設定