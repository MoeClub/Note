#!/bin/bash

EthName=`cat /proc/net/dev |grep ':' |cut -d':' -f1 |sed 's/\s//g' |grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn' |sed -n '1p'`
[ -n "$EthName" ] || exit 1

MyPath="$(dirname `readlink -f "$0"`)"
MyConfig="${MyPath}/ocserv.conf"
[ -f "${MyConfig}" ] || exit 1
MyPort=`cat "${MyConfig}" |grep '#\?tcp-port' |cut -d"=" -f2 |sed 's/\s//g' |grep -o '[0-9]*'`
MyUDP=`cat "${MyConfig}" |grep '#\?udp-port' |cut -d"=" -f2 |sed 's/\s//g' |grep -o '[0-9]*'`


iptables -t nat -A POSTROUTING -o ${EthName} -j MASQUERADE
[ -n "$MyPort" ] && iptables -I INPUT -p tcp --dport ${MyPort} -j ACCEPT
[ -n "$MyUDP" ] && iptables -I INPUT -p udp --dport ${MyUDP} -j ACCEPT
iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu


START(){
  kill -9 $(ps -C ocserv -o pid=) >>/dev/null 2>&1;
  kill -9 $(ps -C ocserv-main -o pid=) >>/dev/null 2>&1;
  ocserv --config "${MyConfig}" >>/dev/null 2>&1;
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
[ $? -ne 0 ] && START; exit 0

while true; do SCAN; done
