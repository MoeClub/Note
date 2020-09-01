#!/bin/bash

EthName=`cat /proc/net/dev |grep ':' |cut -d':' -f1 |sed 's/\s//g' |grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn' |sed -n '1p'`
[ -n "$EthName" ] || exit 1
DIR=`dirname "$0"`
TCP=`cat "${DIR}/ocserv.conf" |grep '#\?tcp-port' |cut -d"=" -f2 |sed 's/\s//g'`
UDP=`cat "${DIR}/ocserv.conf" |grep '#\?udp-port' |cut -d"=" -f2 |sed 's/\s//g'`
iptables -t nat -A POSTROUTING -o ${EthName} -j MASQUERADE
[ -n "$TCP" ] && iptables -I INPUT -p tcp --dport ${TCP} -j ACCEPT
[ -n "$UDP" ] && iptables -I INPUT -p udp --dport ${UDP} -j ACCEPT
iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
