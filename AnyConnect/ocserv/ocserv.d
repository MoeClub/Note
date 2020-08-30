#!/bin/bash

MyPath="$(dirname `readlink -f "$0"`)"
MyPort="$(cat ${MyPath}/ocserv.conf |grep '^tcp-port' |grep -o '[0-9]*')"
MyStartUp="/etc/init.d/ocserv"
[ -e "$(which nc)" ] || exit 1
[ -e ${MyStartUp} ] || exit 1

PORT_STATUS(){
  nc -w 1 -vz 0.0.0.0 ${MyPort} >/dev/null 2>&1
  [[ "$?" == "0" ]] && echo "0" || echo "1"
}

SCAN(){
  if [[ "$(PORT_STATUS)" == "0" ]]; then
    sleep 300;
  else
    kill -9 <(ps -C ocserv -o pid=) 1>/dev/null 2>&1
    bash ${MyStartUp} restart 1>/dev/null 2>&1 &
    sleep 10;
  fi
}

while true; do SCAN; done
