#!/bin/bash

MyPath="$(dirname `readlink -f "$0"`)"
MyPort="$(cat ${MyPath}/ocserv.conf |grep '^tcp-port' |grep -o '[0-9]*')"
MyStartUp="/etc/init.d/ocserv"
command -v nc >>/dev/null 2>&1
[ $? -ne 0 ] && exit 1
[ -e ${MyStartUp} ] || exit 1

PORT_STATUS(){
  nc -w 1 -vz 0.0.0.0 ${MyPort} >/dev/null 2>&1
  [[ "$?" == "0" ]] && echo "0" || echo "1"
}

SCAN(){
  if [[ "$(PORT_STATUS)" == "0" ]]; then
    sleep 300;
  else
    bash ${MyStartUp} restart
    sleep 10;
  fi
}

while true; do SCAN; done
