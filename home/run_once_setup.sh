#!/bin/bash
set -e

echo "🚀 Starting development environment setup..."

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install packages from the rendered Brewfile (applied to ~/Brewfile before scripts run)
echo "📦 Installing Homebrew packages..."
BREWFILE="$HOME/Brewfile"

if [ ! -f "$BREWFILE" ]; then
    echo "No Brewfile found"
    exit 1
fi

# Install missing packages only; upgrades are a deliberate `brew upgrade`,
# so a setup.sh edit never triggers multi-GB cask re-downloads.
if ! brew bundle --no-upgrade --file="$BREWFILE"; then
    echo "⚠️  Some packages may have had warnings during installation (this is normal for apps like Zoom)"
    # Check if critical tools were installed
    if command -v mise &>/dev/null; then
        echo "✅ Critical tools were installed successfully"
    else
        echo "❌ Critical tools installation failed"
        exit 1
    fi
fi

# Install Oh My Zsh if not installed (KEEP_ZSHRC prevents it from replacing the managed ~/.zshrc)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🎨 Installing Oh My Zsh..."
    KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install global tools declared in ~/.config/mise/config.toml
if command -v mise &>/dev/null; then
    echo "📦 Installing global tools with mise..."
    mise install
fi

# Install uv (manages Python versions)
if ! command -v uv &>/dev/null; then
    echo "🐍 Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Install the herdr integration for Codex (writes ~/.codex/{herdr-agent-state.sh,hooks.json})
# The Claude Code side is managed by chezmoi instead: `herdr integration install claude`
# would write a machine-specific absolute path into the repo-symlinked settings.json.
if command -v herdr &>/dev/null; then
    echo "🐑 Installing herdr integration..."
    herdr integration install codex

    # Install herdr plugins (keybindings live in ~/.config/herdr/config.toml)
    herdr plugin list --json 2>/dev/null | grep -q '"herdr-file-viewer"' \
        || herdr plugin install smarzban/herdr-file-viewer --yes

    # Install the herdr agent skill (~/.agents/skills/herdr, symlinked into supported agents)
    if command -v npx &>/dev/null && [ ! -d "$HOME/.agents/skills/herdr" ]; then
        npx -y skills add ogulcancelik/herdr --skill herdr -g
    fi
fi

# Install App Store apps. Skipped in CI: runners cannot sign in and
# mas install hangs instead of failing fast.
if command -v mas &>/dev/null && [ -z "${CI:-}" ]; then
    echo "📚 Installing App Store apps..."
    mas list | grep -q "^302584613" \
        || mas install 302584613 \
        || echo "⚠️  Skipped Kindle (sign in to the App Store and re-run: mas install 302584613)"
fi

# Install Claude Code CLI (native installer, self-updating)
if ! command -v claude &>/dev/null; then
    echo "🤖 Installing Claude Code CLI..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    echo "✅ Claude Code CLI is already installed"
fi

# Install Google Cloud SDK
if [ ! -x "$HOME/.google-cloud-sdk/bin/gcloud" ]; then
    echo "☁️  Installing Google Cloud SDK..."
    GCLOUD_ARCHIVE="google-cloud-cli-darwin-arm.tar.gz"

    # Create temporary directory for installation
    TEMP_DIR=$(mktemp -d)
    echo "📁 Using temporary directory: $TEMP_DIR"
    
    # Save current directory
    CURRENT_DIR=$(pwd)
    
    # Change to temp directory
    cd "$TEMP_DIR"
    
    # Download and extract
    echo "📥 Downloading Google Cloud SDK..."
    curl -O "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/$GCLOUD_ARCHIVE"
    tar -xf "$GCLOUD_ARCHIVE"
    
    # Install to home directory
    GCLOUD_INSTALL_DIR="$HOME/.google-cloud-sdk"
    if [ -d "$GCLOUD_INSTALL_DIR" ]; then
        echo "🗑️  Removing existing Google Cloud SDK installation..."
        rm -rf "$GCLOUD_INSTALL_DIR"
    fi
    
    # Move to permanent location
    mv google-cloud-sdk "$GCLOUD_INSTALL_DIR"
    
    # Run installer
    echo "🔧 Running Google Cloud SDK installer..."
    "$GCLOUD_INSTALL_DIR/install.sh" --quiet
    
    # Return to original directory
    cd "$CURRENT_DIR"
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
    echo "✅ Google Cloud SDK installed successfully"
else
    echo "✅ Google Cloud SDK is already installed"
fi

echo "✅ Development environment setup complete!"
echo "Please restart your terminal or run: source ~/.zshrc"
