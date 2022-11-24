#!/bin/bash

[ -f "/usr/bin/sudo" ] || exit 1
[ "$(sudo whoami)" == "root" ] || exit 1

echo -e "\n# Reset SMC [Shutdown, Shift + Control + Option + PowerButton]"

echo -e "\n# SIP status [Command + R]"
sudo csrutil status

echo -e "\n# System setting ..."
sudo nvram -c >/dev/null 2>&1
sudo nvram StartupMute=%01
sudo defaults write com.apple.loginwindow TALLogoutSavesState -bool FALSE
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist 2>/dev/null
