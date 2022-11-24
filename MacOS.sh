#!/bin/bash

[ -f "/usr/bin/sudo" ] || exit 1;
[ "$(sudo whoami)" == "root" ] || exit 1;

sudo nvram -c >/dev/null 2>&1
sudo nvram StartupMute=%01
sudo defaults write com.apple.loginwindow TALLogoutSavesState -bool FALSE
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist 2>/dev/null

sipStatus="$(csrutil status |cut -d':' -f2 |grep -io 'enable\|disable')"
sipAuthStatus="$(csrutil authenticated-root status |cut -d':' -f2 |grep -io 'enable\|disable')"

[ "$sipStatus" == "disable" ] && [ "$sipAuthStatus" == "disable" ] || {
echo -e "\n# SIP status [Command + R]\n--> csrutil disable\n--> csrutil authenticated-root disable\n"
exit 1;
}

temp="/tmp/MacOS"
volume="/Volumes/$(ls -1 /Volumes|head -n1)"
disk=`sudo mount |grep ' on / ' |cut -d' ' -f1 |cut -b1-12`
[ -n "$volume" ] && [ -n "$disk" ] || exit 1
mkdir -p "$temp" || exit 1

echo -e "Volume: $volume\nDisk: $disk\nTemp: $temp"

sudo umount "$disk" >/dev/null 2>&1
sudo mount -o nobrowse -t apfs "$disk" "$temp"
[ $? -eq 0 ] || exit 1

read -p "Please Edit System File and Press <ENTER>"


sudo bless --folder "$temp/System/Library/CoreServices" --bootefi --create-snapshot
[ $? -ne 0 ] && echo "Create Snapshot Fail." && exit 1
sudo diskutil apfs listSnapshots "$volume"
