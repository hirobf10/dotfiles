#!/bin/bash
set -e

echo "🚀 Starting development environment setup..."

# Install Homebrew if not installed
if ! command -v brew &>/dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH based on system architecture
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        # Apple Silicon
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        # Intel Mac
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Install packages from Brewfile
echo "📦 Installing Homebrew packages..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"

if [ ! -f "$BREWFILE" ]; then
    # When run by chezmoi, script is in ~/.local/share/chezmoi
    BREWFILE="$HOME/.local/share/chezmoi/Brewfile"
fi

if [ ! -f "$BREWFILE" ]; then
    echo "No Brewfile found"
    exit 1
fi

# Run brew bundle with error handling for known issues
if ! brew bundle --file="$BREWFILE"; then
    echo "⚠️  Some packages may have had warnings during installation (this is normal for apps like Zoom)"
    # Check if critical tools were installed
    if command -v anyenv &>/dev/null && command -v direnv &>/dev/null; then
        echo "✅ Critical tools were installed successfully"
    else
        echo "❌ Critical tools installation failed"
        exit 1
    fi
fi

# Install Oh My Zsh if not installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🎨 Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Setup pyenv
if command -v pyenv &>/dev/null; then
    echo "🐍 Setting up Python with pyenv..."
    # Set PYENV_ROOT if not already set
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
fi

# Setup anyenv
if command -v anyenv &>/dev/null; then
    echo "📦 Initializing anyenv..."
    # Initialize anyenv
    eval "$(anyenv init -)"
    
    # Install anyenv-install plugin
    if [ ! -d "$HOME/.config/anyenv/anyenv-install" ]; then
        echo "📥 Installing anyenv-install plugin..."
        git clone https://github.com/anyenv/anyenv-install.git "$HOME/.config/anyenv/anyenv-install"
    fi
    
    # Check if anyenv is properly initialized
    if anyenv versions &>/dev/null; then
        # Install nodenv if not already installed
        if ! anyenv versions | grep -q nodenv; then
            echo "🟢 Installing nodenv via anyenv..."
            anyenv install nodenv
            eval "$(anyenv init -)"
        fi

        # Install pyenv if not already installed
        if ! anyenv versions | grep -q pyenv; then
            echo "🐍 Installing pyenv via anyenv..."
            anyenv install pyenv
            eval "$(anyenv init -)"
        fi
        
        # Install tfenv if not already installed
        if ! anyenv versions | grep -q tfenv; then
            echo "🔧 Installing tfenv via anyenv..."
            anyenv install tfenv
            eval "$(anyenv init -)"
        fi
        
        # Install Python via pyenv
        if command -v pyenv &>/dev/null; then
            echo "🐍 Installing latest Python 3.12..."
            # Get latest Python 3.12 version
            LATEST_PYTHON_312=$(pyenv install --list | grep -E "^\s*3\.12\.[0-9]+$" | tail -1 | xargs)
            if [ -n "$LATEST_PYTHON_312" ]; then
                echo "📦 Installing Python $LATEST_PYTHON_312..."
                pyenv install -s "$LATEST_PYTHON_312"
                pyenv global "$LATEST_PYTHON_312"
                eval "$(pyenv init -)"
            else
                echo "⚠️  Could not find Python 3.12 version. Installing 3.12.0..."
                pyenv install -s 3.12.0
                pyenv global 3.12.0
                eval "$(pyenv init -)"
            fi
        fi
        
        # Install Node.js via nodenv
        if command -v nodenv &>/dev/null; then
            echo "🟢 Installing latest Node.js LTS..."
            # Get latest LTS version (even numbered major versions)
            LATEST_NODE_LTS=$(nodenv install --list | grep -E "^\s*[0-9]+\.[0-9]+\.[0-9]+$" | grep -E "^\s*(18|20|22)\." | tail -1 | xargs)
            if [ -n "$LATEST_NODE_LTS" ]; then
                echo "📦 Installing Node.js $LATEST_NODE_LTS..."
                nodenv install -s "$LATEST_NODE_LTS"
                nodenv global "$LATEST_NODE_LTS"
                eval "$(nodenv init -)"
            else
                echo "⚠️  Could not find Node.js LTS version. Installing 20.11.0..."
                nodenv install -s 20.11.0
                nodenv global 20.11.0
                eval "$(nodenv init -)"
            fi
        fi
        
        # Install Terraform via tfenv
        if command -v tfenv &>/dev/null; then
            echo "🔧 Installing latest Terraform..."
            # Get latest stable version
            LATEST_TERRAFORM=$(tfenv list-remote | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | head -1)
            if [ -n "$LATEST_TERRAFORM" ]; then
                echo "📦 Installing Terraform $LATEST_TERRAFORM..."
                tfenv install "$LATEST_TERRAFORM"
                tfenv use "$LATEST_TERRAFORM"
            else
                echo "⚠️  Could not find Terraform version. Installing 1.7.0..."
                tfenv install 1.7.0
                tfenv use 1.7.0
            fi
        fi
    else
        echo "⚠️  anyenv is not fully initialized. Run 'anyenv install --init' manually."
    fi
fi

# Setup direnv (already in .zshrc)
echo "📁 direnv is configured in .zshrc"

# Install Claude Code CLI
if ! command -v claude &>/dev/null; then
    echo "🤖 Installing Claude Code CLI..."
    if command -v npm &>/dev/null; then
        npm install -g @anthropic-ai/claude-code
    else
        echo "⚠️  npm not found. Install Node.js first, then run: npm install -g @anthropic-ai/claude-code"
    fi
else
    echo "✅ Claude Code CLI is already installed"
fi

# Install Google Cloud SDK
if ! command -v gcloud &>/dev/null; then
    echo "☁️  Installing Google Cloud SDK..."
    
    # Determine architecture
    if [[ $(uname -m) == "arm64" ]]; then
        GCLOUD_ARCHIVE="google-cloud-cli-darwin-arm.tar.gz"
    else
        GCLOUD_ARCHIVE="google-cloud-cli-darwin-x86_64.tar.gz"
    fi
    
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
