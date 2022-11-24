#!/bin/bash

Plist="${1:-com.navicat.NavicatPremium.plist}"

defaults read "$Plist" |grep '{' |grep '[0-9A-Z]\{32\}' |cut -d'=' -f1 |sed 's/[[:space:]]//g' |xargs -I {} defaults delete "$Plist" "{}"
find "$HOME/Library/Application Support/PremiumSoft CyberTech/Navicat CC/Navicat Premium" -type f -name ".*" -delete
