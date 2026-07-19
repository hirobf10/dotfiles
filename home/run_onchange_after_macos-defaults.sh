#!/bin/bash
# macOS defaults. Runs after setup.sh whenever this file changes.
# To find the key for a GUI setting: `defaults read > /tmp/before`,
# change the setting in System Settings, `defaults read > /tmp/after`, diff.

set -eu

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

echo "✅ macOS defaults applied"
