#!/bin/bash
# macOS defaults. Runs after setup.sh whenever this file changes.
# To find the key for a GUI setting: `defaults read > /tmp/before`,
# change the setting in System Settings, `defaults read > /tmp/after`, diff.

set -eu

# Runs standalone from any shell: brew's bin is not on bash's default PATH
export PATH="/opt/homebrew/bin:$PATH"

echo "🍎 Applying macOS defaults..."

# Input sources: US (ABC) layout + Japanese romaji input.
# With this combo, Caps Lock toggles ABC/Japanese (TISRomanSwitchKey).
# Guarded: only written when Kotoeri is missing, to avoid clobbering the
# system-managed palette entries in the same array. Takes effect after logout.
if ! defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | grep -q "Kotoeri.RomajiTyping"; then
    defaults write com.apple.HIToolbox AppleEnabledInputSources -array \
        '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>252</integer><key>KeyboardLayout Name</key><string>ABC</string></dict>' \
        '<dict><key>Bundle ID</key><string>com.apple.inputmethod.Kotoeri.RomajiTyping</string><key>Input Mode</key><string>com.apple.inputmethod.Japanese</string><key>InputSourceKind</key><string>Input Mode</string></dict>' \
        '<dict><key>Bundle ID</key><string>com.apple.inputmethod.Kotoeri.RomajiTyping</string><key>InputSourceKind</key><string>Keyboard Input Method</string></dict>'
    echo "Input sources configured (log out to take effect)"
fi
defaults write com.apple.HIToolbox TISRomanSwitchKey -int 1

# Default browser: Chrome. No-op when already default; otherwise macOS
# shows a one-time confirmation dialog.
if command -v defaultbrowser >/dev/null 2>&1; then
    defaultbrowser chrome || true
fi

# Keyboard: fast key repeat (beyond the GUI maximum), no accent popup on hold.
# Applies to apps started after the next login.
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
defaults write -g ApplePressAndHoldEnabled -bool false

# Screenshots: dedicated folder, no window shadow
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true

# Finder: show all extensions and the path bar
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true

# Text input: no auto-corrections that mangle code
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false

# Dock / Spaces: no recent apps, keep Spaces order fixed
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false

# Finder QoL: new windows open home, no extension-change warning,
# no .DS_Store on network/USB volumes
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Misc QoL: battery percentage, expanded save dialogs
defaults write com.apple.controlcenter BatteryShowPercentage -bool true
defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool true

killall Dock Finder SystemUIServer ControlCenter 2>/dev/null || true

echo "✅ macOS defaults applied"
