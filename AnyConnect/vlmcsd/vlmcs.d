#!/bin/bash

MyARG=`echo "$1" |sed 's/^\s$//' |sed 's/[a-z]/\u&/g'`
MyPort="1688"
MyPath="$(dirname `readlink -f "$0"`)"
MyExec="${MyPath}/vlmcsdmulti"

[ -f "${MyExec}" ] || exit 1
[ -n "$MyPort" ] && iptables -I INPUT -p tcp --dport ${MyPort} -j ACCEPT

INIT(){
  MyCMD=`echo "$1" |sed 's/^\s$//'`
  [ -n "${MyCMD}" ] || MyCMD=`readlink -f "$0"`
  [ -n "${MyCMD}" ] && MyDEL=$(echo "${MyCMD}" |tr '/' '\\\\' |sed 's/\\/\\\//g')
  [ -n "${MyDEL}" ] || return
  if [ -f /etc/crontab ]; then
    sed -i "/${MyDEL}/d" /etc/crontab
    while [ -z "$(sed -n '$p' /etc/crontab |sed 's/^\s$//')" ]; do sed -i '$d' /etc/crontab; done
    sed -i "\$a\\@reboot root ${MyCMD} >>/dev/null 2>&1 &" /etc/crontab
    sed -i '$a\\n\n\n' /etc/crontab
  fi
}

STOP(){
  kill -9 $(ps -C vlmcsd -o pid=) >>/dev/null 2>&1;
  kill -9 $(ps -C vlmcsdmulti -o pid=) >>/dev/null 2>&1;
}

START(){
  STOP;
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


if [ "$MyARG" == "INIT" ]; then
  INIT;
  exit 0;
elif [ "$MyARG" == "START" ]; then
  START;
  exit 0;
elif [ "$MyARG" == "STOP" ]; then
  STOP;
  exit 0;
fi

command -v nc >>/dev/null 2>&1
if [ $? -ne 0 ]; then
  START;
  exit 0;
fi

while true; do SCAN; done

