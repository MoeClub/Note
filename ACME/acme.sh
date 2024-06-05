#!/bin/bash

DOMAIN=()
DOMAIN+=("moeclub.org,*.moeclub.org")
# DOMAIN+=("moeclub.org,*.moeclub.org")

cd $(dirname `readlink -f "$0"`)
[ -f "./acme.py" ] || exit 1
[ -f "./acme/dv.acme-v02.api.pki.goog/acme.key" ] && s="google" || s="letsencrypt"

for domain in "${DOMAIN[@]}"; do
  _domain="${domain};"
  domain=`echo "${_domain}" |cut -d';' -f1`
  sub=`echo "${_domain}" |cut -d';' -f2`
  if [ "${s}" == "letsencrypt" ]; then
    python3 ./acme.py -s "${s}" -ecc -d "${domain}" -sub "${sub}"
  else
    python3 ./acme.py -s "${s}" -d "${domain}" -sub "${sub}"
  fi
done


