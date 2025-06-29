#!/bin/bash
## systemctl enable nftables
## nft -a list ruleset

RemoteAddr="${1:-}"
LocalPort="${2:-443}"

[ "$(cat /proc/sys/net/ipv4/ip_forward)" != "1" ] && echo "1" >/proc/sys/net/ipv4/ip_forward

nft list table ip nat >/dev/null 2>&1 || nft add table ip nat
nft list chain ip nat prerouting >/dev/null 2>&1 || nft add chain ip nat prerouting { type nat hook prerouting priority dstnat \; policy accept \; }
nft list chain ip nat postrouting >/dev/null 2>&1 || nft add chain ip nat postrouting { type nat hook postrouting priority srcnat \; policy accept \; }


nft insert rule ip nat prerouting tcp dport "${LocalPort}"  dnat to "${RemoteAddr}"
nft insert rule ip nat postrouting ip daddr "${RemoteAddr%:*}" tcp dport "${RemoteAddr#*:}" masquerade
nft insert rule inet filter forward ip daddr "${RemoteAddr%:*}" tcp dport "${RemoteAddr#*:}" ip dscp set 46
nft insert rule inet filter forward ip saddr "${RemoteAddr%:*}" tcp sport "${RemoteAddr#*:}" ip dscp set 46

