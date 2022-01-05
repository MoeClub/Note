#!/bin/bash

RemoteAddress="${1:-}"
LocalPort="${2:-443}"
LocalIf="${3:-}"

function getInterface(){
  interface=""
  Interfaces=`cat /proc/net/dev |grep ':' |cut -d':' -f1 |sed 's/\s//g' |grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn'`
  defaultRoute=`ip route show default |grep "^default"`
  for item in `echo "$Interfaces"`
    do
      [ -n "$item" ] || continue
      echo "$defaultRoute" |grep -q "$item"
      [ $? -eq 0 ] && interface="$item" && break
    done
  echo "$interface"
}

echo "${RemoteAddress}" |grep -q "[0-9a-zA-Z\.]\+:[0-9]\{1,5\}"
[ "$?" -ne 0 ] && echo "Invalid RemoteAddress(Host:Port)" && exit 1
RemoteHost="$(host $(echo ${RemoteAddress} |cut -d: -f1) |grep -o '[0-9\.]\{1,3\}\.[0-9\.]\{1,3\}\.[0-9\.]\{1,3\}\.[0-9\.]\{1,3\}')"
RemotePort="$(echo ${RemoteAddress} |cut -d: -f2 |grep -o '[0-9]\{1,5\}')"

[ ! -n "${RemoteHost}" ] && echo "Invalid RemoteHost" && exit 1

[ -n "$LocalIf" ] || LocalIf="$(getInterface)"

[ "$(cat /proc/sys/net/ipv4/ip_forward)" != "1" ] && echo "1" >/proc/sys/net/ipv4/ip_forward

iptables -I INPUT -p tcp --dport ${LocalPort} -j ACCEPT
iptables -t nat -A PREROUTING -p tcp -i ${LocalIf} --dport ${LocalPort} -j DNAT --to-destination ${RemoteHost}:${RemotePort}
iptables -t nat -I POSTROUTING -d ${RemoteHost} -p tcp --dport ${RemotePort} -j MASQUERADE

