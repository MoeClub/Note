#!/bin/bash

HostName="google.com"
HostPort="443"
LocalPort="443"
LocalIf="eth0"

RemoteHost=`curl -o /dev/null -sSL --connect-timeout 5 --retry-delay 3 --retry 5 -w %{remote_ip} "https://${HostName}:${HostPort}"`
[ -n "$RemoteHost" ] || exit 1

Forward=`cat /proc/sys/net/ipv4/ip_forward`
[ "$Forward" != "1" ] && echo "1" >/proc/sys/net/ipv4/ip_forward

iptables -I INPUT -p tcp --dport ${LocalPort} -j ACCEPT
iptables -t nat -A PREROUTING -p tcp -i ${LocalIf} --dport ${LocalPort} -j DNAT --to-destination ${RemoteHost}:${HostPort}
iptables -t nat -I POSTROUTING -d ${RemoteHost} -p tcp --dport ${HostPort} -j MASQUERADE

