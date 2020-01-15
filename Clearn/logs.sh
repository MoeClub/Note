#!/bin/bash

UserHome=`echo "$HOME"`

[[ "$(sudo whoami)" == "root" ]] || exit 1
[ -d /var/log ] && sudo find /var/log -type f -delete
[ -d /Library/Logs ] && sudo find /Library/Logs -type f -delete
[ -d ${UserHome} ] && sudo find ${UserHome} -type f -name ".*_history" -maxdepth 1 -delete
[ -d ${UserHome}/Library/Logs ] && sudo find ${UserHome}/Library/Logs -type f -delete
[ -d ${UserHome}/.cisco ] && sudo rm -rf ${UserHome}/.cisco

