#!/bin/bash

# /etc/crontab
# 0 4 * * 3 root bash /full/path/to/acme.sh 1>/dev/null 2>&1 &

DOMAIN=()
DOMAIN+=("moeclub.org,*.moeclub.org")
# DOMAIN+=("moeclub.org,*.moeclub.org")

cd $(dirname `readlink -f "$0"`)
[ -f "./acme.py" ] || exit 1
[ -f "./dv.acme-v02.api.pki.goog/acme.key" ] && s="google" || s="letsencrypt"

for domain in "${DOMAIN[@]}"; do
  _domain="${domain};"
  domain=`echo "${_domain}" |cut -d';' -f1`
  sub=`echo "${_domain}" |cut -d';' -f2`
  python3 ./acme.py -s "${s}" -d "${domain}" -sub "${sub}"
done
