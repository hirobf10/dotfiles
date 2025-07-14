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

このコマンドはデフォルト値で環境をセットアップします。個人情報を更新するには：
```bash
chezmoi edit-config  # 名前、メールアドレスを設定
chezmoi apply        # 変更を適用
```

## 環境設定

`~/.config/chezmoi/chezmoi.toml`を編集して、以下を設定：
- `name`: あなたの名前
- `environment`: `work` または `personal`
- `work_email`: 仕事用メールアドレス
- `personal_email`: 個人用メールアドレス

## 開発環境セットアップ

```bash
chezmoi cd
./scripts/setup.sh
```

自動インストール内容：
- Homebrew、Oh My Zsh
- anyenv（pyenv、nodenv、tfenv）
- Python 3.12、Node.js LTS、Terraform最新版
- VSCode拡張機能（`brew bundle`経由）
- その他開発ツール（詳細は`scripts/Brewfile`参照）

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