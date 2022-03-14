#!/bin/bash

ARG=`echo "$1" |sed 's/^\s$//' |sed 's/[a-z]/\u&/g'`

ConfigPath="$(dirname `readlink -f "$0"`)"
Config="${ConfigPath}/ocserv.conf"
[ -f "$Config" ] || exit 1

TCP=`cat "${Config}" |grep '^#\?tcp-port' |cut -d"=" -f2 |grep -o '[0-9]*' |head -n1`
UDP=`cat "${Config}" |grep '^#\?udp-port' |cut -d"=" -f2 |grep -o '[0-9]*' |head -n1`

function GetAddress(){
  echo `wget --no-check-certificate --timeout=3 --no-cache -4 -qO- "http://checkip.amazonaws.com" |grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' |head -n1`
}

function IPTABLES(){
  RULE=`echo "$1" |sed 's/^\s*//' |sed 's/\s*$//'`
  echo "$RULE" |grep -q "^iptables "
  [ $? -eq 0 ] || return 1
  CHECK=`echo "$RULE" |sed 's/-I\|-A/-C/'`
  ${CHECK} >>/dev/null 2>&1
  [ $? -eq 1 ] && ${RULE} 
  return 0
}

function GenPasswd(){
  RawPasswd="${1:-MoeClub}"
  UserPasswd=`openssl passwd ${RawPasswd}`
  echo -e "\nUserName\tGroup\t\tPassword\n\nDefault\t\tDefault\t\t${RawPasswd}\nRoute\t\tRoute\t\t${RawPasswd}\nNoRoute\t\tNoRoute\t\t${RawPasswd}\nNull\t\tNull\t\t${RawPasswd}\n"
  echo -e "Default:Default:${UserPasswd}\nRoute:Route:${UserPasswd}\nNoRoute:NoRoute:${UserPasswd}\nNull:Null:${UserPasswd}\n" >/etc/ocserv/ocpasswd
  chmod 755 /etc/ocserv/ocpasswd
}

if [ "$ARG" == "CHECK" ]; then
  TCPHEX=`printf '%04X\n' "${TCP}"`
  cat /proc/net/tcp |grep -q "^\s*[0-9]\+:\s*[0-9A-Za-z]\+:${TCPHEX}\s*[0-9A-Za-z]\+:[0-9A-Za-z]\+\s*0A\s*"
  [ "$?" -eq 0 ] && exit 0 || exit 1
elif [ "$ARG" == "INIT" ]; then
  openssl req -x509 -sha256 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 3650 -subj "/C=/ST=/L=/O=/OU=/CN=*" -addext "keyUsage=critical, digitalSignature" -outform PEM -keyout "${ConfigPath}/server.key.pem" -out "${ConfigPath}/server.cert.pem"
  chown -R root:root "${ConfigPath}"
  chmod -R 755 "${ConfigPath}"
  if [ -d "/etc/systemd/system" ] && [ -f "${ConfigPath}/ocserv.service" ]; then
    systemctl stop ocserv.service >/dev/null 2>&1
    systemctl disable ocserv.service >/dev/null 2>&1
    cp -rf "${ConfigPath}/ocserv.service" "/etc/systemd/system/ocserv.service"
    chmod 755 "/etc/systemd/system/ocserv.service"
    systemctl daemon-reload >/dev/null 2>&1
    systemctl enable ocserv.service >/dev/null 2>&1
    systemctl start ocserv.service >/dev/null 2>&1
  fi
  GenPasswd;
  echo -e "Set Password Command:\n\tbash ${ConfigPath}/ctl.sh passwd <PASSWORD>\n"
  exit 0
elif [ "$ARG" == "PASSWD" ]; then
  [ -n "$2" ] && GenPasswd "$2" && exit 0 || exit 1
fi

Ether=`ip route show default |sed 's/.*dev\s*\([0-9a-zA-Z]\+\).*/\1/g'`
[ -n "$Ether" ] || exit 1

[ -f "${ConfigPath}/group/NoRoute" ] && Address="$(GetAddress)" && [ -n "$Address" ] &&  sed -i "s/^no-route\s*=\s*.*\/255.255.255.255/no-route = ${Address}\/255.255.255.255/" "${ConfigPath}/group/NoRoute"

IPTABLES "iptables -t nat -A POSTROUTING -o ${Ether} -j MASQUERADE"
IPTABLES "iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu"
[ -n "$TCP" ] && [ "$TCP" -gt "0" ] && IPTABLES "iptables -I INPUT -p tcp --dport ${TCP} -j ACCEPT"
[ -n "$UDP" ] && [ "$UDP" -gt "0" ] && IPTABLES "iptables -I INPUT -p udp --dport ${UDP} -j ACCEPT"

[ `cat /proc/sys/net/ipv4/ip_forward` != "1" ] && echo "1" >/proc/sys/net/ipv4/ip_forward

exit 0