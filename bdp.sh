#!/bin/bash

Bandwidth="${1:-1000}"   # MB
RTT="${2:-60}"           # ms
BDP=`echo "${Bandwidth} ${RTT}" |awk '{printf "%d", ($1 * $2) * ((1024 * 1024) / (1000 * 8))}' 2>/dev/null`
[ -n "$BDP" ] && [ "$BDP" -gt 0 ] || exit 1

sysctl -w net.core.rmem_max="${BDP}"
sysctl -w net.core.wmem_max="${BDP}"
sysctl -w net.ipv4.tcp_rmem="4096 87380 ${BDP}"
sysctl -w net.ipv4.tcp_wmem="4096 16384 ${BDP}"
sysctl -w net.ipv4.tcp_window_scaling=1
sysctl -w net.ipv4.route.flush=1
