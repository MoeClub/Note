#!/bin/bash

Bandwidth="${1:-1000}"   # MB
RTT="${2:-60}"           # ms
BDP=`echo "${Bandwidth} ${RTT}" |awk '{printf "%d", ($1 * $2) * ((1024 * 1024) / (1000 * 8))}' 2>/dev/null`
[ -n "$BDP" ] && [ "$BDP" -gt 0 ] || exit 1

cat >/etc/sysctl.conf<<EOF
# This line below add by user.

fs.file-max = 104857600
fs.nr_open = 1048576

vm.overcommit_memory = 1

net.core.somaxconn = 1048576
net.core.optmem_max = 7864320
net.core.rmem_max = 7864320
net.core.wmem_max = 7864320
net.core.rmem_default = 7864320
net.core.wmem_default = 7864320
net.core.netdev_max_backlog = 1048576
net.core.default_qdisc = fq_codel

net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mem = 32768 49152 65536
net.ipv4.tcp_rmem = 4096 87380 7864320
net.ipv4.tcp_wmem = 4096 16384 7864320
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 1048576
net.ipv4.tcp_fin_timeout = 8
net.ipv4.tcp_keepalive_intvl = 32
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_time = 900
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.ip_forward = 1

net.ipv4.tcp_fastopen = 0
net.ipv4.tcp_fack = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_ecn_fallback = 1


net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.all.proxy_ndp = 1





EOF
