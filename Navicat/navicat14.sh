#!/bin/bash

Plist="${1:-com.navicat.NavicatPremium.plist}"

defaults write "$Plist" SUHasLaunchedBefore -int 0;
defaults read "$Plist" |grep '{' |grep -o '[0-9A-Z]\{32\}' |xargs -I {} defaults delete "$Plist" "{}"
find "$HOME/Library/Application Support/PremiumSoft CyberTech/Navicat CC/Navicat Premium" -type f -name ".*" -delete
