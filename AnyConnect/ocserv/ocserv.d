#!/bin/bash
# Autorun whit crontab by MoeClub


MyARG=`echo "$1" |sed 's/^\s$//' |sed 's/[a-z]/\u&/g'`
EthName=`cat /proc/net/dev |grep ':' |cut -d':' -f1 |sed 's/\s//g' |grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn' |sed -n '1p'`
[ -n "$EthName" ] || exit 1

MyPath="$(dirname `readlink -f "$0"`)"
MyConfig="${MyPath}/ocserv.conf"
[ -f "${MyConfig}" ] || exit 1

MyPort=`cat "${MyConfig}" |grep '#\?tcp-port' |cut -d"=" -f2 |sed 's/\s//g' |grep -o '[0-9]*'`
MyUDP=`cat "${MyConfig}" |grep '#\?udp-port' |cut -d"=" -f2 |sed 's/\s//g' |grep -o '[0-9]*'`
MyPublicIP=`wget --no-check-certificate --timeout=3 --no-cache -4 -qO- "http://checkip.amazonaws.com" |grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`


IPTABLES(){
  RULE_RAW=`echo "$1" |sed 's/^\s*//' |sed 's/\s*$//'`
  echo "$RULE_RAW" |grep -q "^iptables"
  [ $? -eq 0 ] || return 1
  RULE_CHECK=`echo "$RULE_RAW" |sed 's/-I\|-A/-C/'`
  ${RULE_CHECK} >>/dev/null 2>&1
  [ $? -eq 1 ] && ${RULE_RAW} 
  return 0
}

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
  DEAMONS=("ocserv" "ocserv-main")
  for deamon in "${DEAMONS[@]}"; do [ -n "$deamon" ] && kill -9 `ps -C "$deamon" -o pid=` >>/dev/null 2>&1; done
}

START(){
  STOP;
  IPTABLES "iptables -t nat -A POSTROUTING -o ${EthName} -j MASQUERADE"
  IPTABLES "iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu"
  [ -n "$MyPort" ] && IPTABLES "iptables -I INPUT -p tcp --dport ${MyPort} -j ACCEPT"
  [ -n "$MyUDP" ] && IPTABLES "iptables -I INPUT -p udp --dport ${MyUDP} -j ACCEPT"
  [ -n "$MyPublicIP" ] && [ -f "${MyPath}/group/NoRoute" ] && sed -i "s/^no-route\s*=\s*.*\/255.255.255.255/no-route = ${MyPublicIP}\/255.255.255.255/" /etc/ocserv/group/NoRoute
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


if [ "$MyARG" == "INIT" ]; then
  INIT;
  exit 0;
elif [ "$MyARG" == "START" ]; then
  START;
  exit 0;
elif [ "$MyARG" == "RESTART" ]; then
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
