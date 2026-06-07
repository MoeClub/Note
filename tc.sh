#!/bin/bash

limit="${1:-200}"
eth=`ip route show default | awk '{for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}'`
[ -n "${eth}" ] && [ "$limit" -gt 0 ] || exit 1
tc qdisc del dev "${eth}" root
tc qdisc replace dev "${eth}" root handle 1: htb default 10
tc class replace dev "${eth}" parent 1: classid 1:10 htb rate "${limit}mbit" ceil "${limit}mbit"
tc qdisc replace dev "${eth}" parent 1:10 fq
