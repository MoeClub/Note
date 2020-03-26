#!/bin/bash

# /etc/crontab
# @reboot root bash /root/redirect/redirect.sh >/dev/null 2>&1 &

CurrentDIR=`dirname "$0"`
for item in `find "$CurrentDIR" -maxdepth 1 -type f -name "redirect_*.sh"`
  do
    bash "${item}" >/dev/null 2>&1 &
  done



