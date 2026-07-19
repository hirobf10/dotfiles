#!/bin/bash
# Dock layout. Separate from macos-defaults.sh so the Dock is only reset
# when this list changes. Manually pinned extras are wiped on re-run.

set -eu

command -v dockutil >/dev/null 2>&1 || exit 0

echo "📌 Applying Dock layout..."
dockutil --no-restart --remove all >/dev/null

for app in \
    "/System/Applications/System Settings.app" \
    "/Applications/Google Chrome.app" \
    "/Applications/Slack.app" \
    "/Applications/Ghostty.app" \
    "/Applications/Claude.app" \
    "/Applications/Codex.app" \
    "/Applications/Amazon Kindle.app" \
    "/Applications/Visual Studio Code.app" \
    "/Applications/Docker.app"; do
    [ -e "$app" ] && dockutil --no-restart --add "$app" >/dev/null
done

killall Dock 2>/dev/null || true
echo "✅ Dock layout applied"
