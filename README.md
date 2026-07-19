# Dotfiles

[![Validate Dotfiles](https://github.com/hirobf10/dotfiles/actions/workflows/validate.yml/badge.svg)](https://github.com/hirobf10/dotfiles/actions/workflows/validate.yml)

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
- mise（Go、Node.js、Terraform、spanner-cli、wrench — `.config/mise/config.toml` で宣言）
- uv（Python 管理）
- Claude Code CLI（公式インストーラ）、gcloud
- その他開発ツール（詳細は`home/Brewfile`参照）

## セットアップ後の手動手順

apply 完了後に残るのは認証・サインイン系のみ：

1. **一度ログアウト → ログイン** — キーリピート・入力ソース等の defaults を反映させる
2. **CLI 認証**
   ```bash
   gh auth login          # 最優先：git の credential helper が gh 依存
   gcloud auth login      # 必要なら gcloud auth application-default login も
   claude                 # 初回起動でログイン
   ```
3. **GUI アプリのサインイン**
   - Chrome（既定ブラウザの確認ダイアログを承認。見逃したら `defaultbrowser chrome`）
   - VSCode → Settings Sync にサインイン（設定・拡張はここで同期される）
   - App Store にサインイン → `mas install 302584613`（Kindle）
   - その他各アプリ
4. **SSH 鍵**（必要な場合のみ） — GitHub は https + gh helper で動くため、鍵が必要なシステムがある場合だけ `ssh-keygen -t ed25519` で生成・登録

## 基本操作

```bash
chezmoi add ~/.dotfile       # ファイル追加
chezmoi diff                 # 差分確認
chezmoi apply                # 変更適用
chezmoi cd                   # ソースディレクトリへ移動
```

## リポジトリ構成

- `.chezmoiroot` により、適用対象のソースは `home/` 配下（リポジトリ直下は README・CI 等のメタ領域）
- `home/dot_config/{agents,claude}/` と `home/dot_mise/` は適用されない実体置き場（`.chezmoiignore` で除外）。`~/.claude/*`・`~/.codex/AGENTS.md`・`~/.config/mise/*` はここへの **symlink** として適用されるため、実ファイルの編集がそのままソース編集になりドリフトしない

## 管理ファイル

### シェル・Git・開発環境
- `.zshrc` - Zsh設定
- `.zprofile` - Homebrew初期化
- `.gitconfig` - Git設定
- `.gitexclude` - グローバル git 除外
- `.config/mise/config.toml` - mise global ツール（symlink 管理）

### AI ツール（symlink 管理）
- `.claude/CLAUDE.md`, `.codex/AGENTS.md` - 開発設定（`dot_config/agents/AGENTS.md` を共有する同一ファイル）
- `.claude/settings.json` - Claude Code 設定（権限・プラグイン）
- `.claude/rules/` - Claude Code ルール（Claude 固有の指示はこちら）