#!/bin/bash


[ -e "$(which nc)" ] || exit 1
MyPath="$(dirname `readlink -f "$0"`)"
MyConfig="${MyPath}/ocserv.conf"
[ -f "${MyConfig}" ] || exit 1
MyPort=`cat "${MyConfig}" |grep '^tcp-port' |grep -o '[0-9]*'`


START(){
  ocserv --config "${MyConfig}" >>/dev/null 2>&1
}

PORT(){
  nc -w 1 -vz 0.0.0.0 ${MyPort} >>/dev/null 2>&1
  [[ "$?" == "0" ]] && echo "0" || echo "1"
}

SCAN(){
  if [[ "$(PORT)" == "0" ]]; then
    sleep 300;
  else
    kill -9 <(ps -C ocserv -o pid=) >>/dev/null 2>&1
    START;
    sleep 10;
  fi
}

while true; do SCAN; done

