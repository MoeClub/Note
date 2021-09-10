#!/bin/bash

RemoteAddress="${1:-}"
LocalPort="${2:-443}"
LocalIf="${3:-eth0}"

echo "${RemoteAddress}" |grep -q "[0-9a-zA-Z\.]\+:[0-9]\{1,5\}"
[ "$?" -ne 0 ] && echo "Invalid RemoteAddress Host:Port" && exit 1

Forward=`cat /proc/sys/net/ipv4/ip_forward`
[ "$Forward" != "1" ] && echo "1" >/proc/sys/net/ipv4/ip_forward

iptables -I INPUT -p tcp --dport ${LocalPort} -j ACCEPT
iptables -t nat -A PREROUTING -p tcp -i ${LocalIf} --dport ${LocalPort} -j DNAT --to-destination ${RemoteAddress}
iptables -t nat -I POSTROUTING -d ${RemoteHost} -p tcp --dport ${HostPort} -j MASQUERADE
