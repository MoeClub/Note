#!/bin/bash

Bandwidth="${1:-1000}"   # MB
RTT="${2:-60}"           # ms
BDP=`echo "${Bandwidth} ${RTT}" |awk '{printf "%d", ($1 * $2) * ((1024 * 1024) / (1000 * 8))}' 2>/dev/null`
[ -n "$BDP" ] && [ "$BDP" -gt 0 ] || BDP="7864320"

cat >/etc/sysctl.conf<<EOF
# This line below add by user.

kernel.pid_max = 65536
kernel.sched_autogroup_enabled = 0

fs.file-max = 104857600
fs.aio-max-nr = 1048576
fs.nr_open = 1048576
fs.inotify.max_user_instances = 10240
fs.inotify.max_user_watches = 1048576
fs.inotify.max_queued_events = 32768

vm.page-cluster = 0
vm.overcommit_memory = 0
vm.oom_kill_allocating_task = 1
vm.max_map_count = 1048576
vm.vfs_cache_pressure = 256
vm.min_free_kbytes = 16384
vm.zone_reclaim_mode = 0
vm.dirty_writeback_centisecs = 100
vm.dirty_expire_centisecs = 1000
vm.dirty_background_ratio = 5
vm.dirty_ratio = 25
vm.swappiness = 10

net.netfilter.nf_conntrack_max = 1048576

net.core.default_qdisc = fq_codel
net.core.netdev_max_backlog = 1048576
net.core.somaxconn = 1048576
net.core.optmem_max = ${BDP}
net.core.rmem_max = ${BDP}
net.core.wmem_max = ${BDP}
net.core.rmem_default = ${BDP}
net.core.wmem_default = ${BDP}
net.core.busy_poll = 0
net.core.busy_read = 0

net.ipv4.ip_forward = 1
net.ipv4.tcp_congestion_control = bbr
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.udp_mem = 32768 49152 65536
net.ipv4.tcp_mem = 32768 49152 65536
net.ipv4.tcp_rmem = 4096 87380 ${BDP}
net.ipv4.tcp_wmem = 4096 16384 ${BDP}
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_fin_timeout = 8
net.ipv4.tcp_keepalive_intvl = 32
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 32768
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 0
net.ipv4.tcp_fack = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_ecn_fallback = 1

net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.all.proxy_ndp = 1


EOF
sysctl -p
sysctl -w net.ipv4.route.flush=1


