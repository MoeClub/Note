#!/bin/bash

MyPort="1688"
MyPath="$(dirname `readlink -f "$0"`)"
MyExec="${MyPath}/vlmcsd"
[ -f "${MyExec}" ] || exit 1
[ -n "$MyPort" ] && iptables -I INPUT -p tcp --dport ${MyPort} -j ACCEPT

START(){
  kill -9 $(ps -C vlmcsd -o pid=) >>/dev/null 2>&1;
  kill -9 $(ps -C vlmcsdmulti -o pid=) >>/dev/null 2>&1;
  "${MyExec}" vlmcsd >>/dev/null 2>&1;
}

PORT(){
  nc -w 1 -vz 0.0.0.0 "${MyPort}" >>/dev/null 2>&1;
  [ "$?" == "0" ] && echo "0" || echo "1";
}

SCAN(){
  if [[ "$(PORT)" == "0" ]]; then
    sleep 300;
  else
    START;
    sleep 10;
  fi
}

command -v nc >>/dev/null 2>&1
if [ $? -ne 0 ]; then
  START;
  exit 0;
fi

while true; do SCAN; done

