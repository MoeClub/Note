#!/bin/bash

apt-get install -y openssl net-tools dnsutils nload curl wget lsof psmisc iptables

if [ -d /etc/systemd ]; then
  apt-get install -y systemd-timesyncd
  if [ -f /etc/systemd/timesyncd.conf ]; then
    echo -ne "[Time]\nNTP=time.apple.com time.windows.com pool.ntp.org ntp.ntsc.ac.cn\nRootDistanceMaxSec=3\nPollIntervalMinSec=24\nPollIntervalMaxSec=512\n\n" >/etc/systemd/timesyncd.conf
    systemctl restart systemd-timesyncd
  fi
fi

# limits
if [ -f /etc/security/limits.conf ]; then
  LIMIT='262144'
  sed -i '/^\(\*\|root\)[[:space:]]*\(hard\|soft\)[[:space:]]*\(nofile\|memlock\)/d' /etc/security/limits.conf
  echo -ne "*\thard\tmemlock\t${LIMIT}\n*\tsoft\tmemlock\t${LIMIT}\nroot\thard\tmemlock\t${LIMIT}\nroot\tsoft\tmemlock\t${LIMIT}\n*\thard\tnofile\t${LIMIT}\n*\tsoft\tnofile\t${LIMIT}\nroot\thard\tnofile\t${LIMIT}\nroot\tsoft\tnofile\t${LIMIT}\n\n" >>/etc/security/limits.conf
fi
if [ -f /etc/systemd/system.conf ]; then
  sed -i 's/#\?DefaultLimitNOFILE=.*/DefaultLimitNOFILE=262144/' /etc/systemd/system.conf
fi

# root
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;

# timezone
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" >/etc/timezone

# systemd-journald
if [ -f /etc/systemd/journald.conf ]; then
  sed -i 's/^#\?Storage=.*/Storage=volatile/' /etc/systemd/journald.conf
  sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=8M/' /etc/systemd/journald.conf
  sed -i 's/^#\?RuntimeMaxUse=.*/RuntimeMaxUse=8M/' /etc/systemd/journald.conf
  sed -i 's/^#\?ForwardToSyslog=.*/ForwardToSyslog=no/' /etc/systemd/journald.conf
  systemctl restart systemd-journald
fi

# ssh
[ -d ~/.ssh ] || mkdir -p ~/.ssh
echo -ne "# chmod 600 ~/.ssh/id_rsa\n\nHost *\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null\n  IdentityFile ~/.ssh/id_rsa\n" > ~/.ssh/config

# nload
echo -ne 'DataFormat="Human Readable (Byte)"\nTrafficFormat="Human Readable (Byte)"\n' >/etc/nload.conf

# sysctl
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

net.ipv4.icmp_echo_ignore_all = 1
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.all.proxy_ndp = 1

net.ipv4.tcp_fastopen = 0
net.ipv4.tcp_fack = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_ecn_fallback = 1

net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = bbr

EOF
sysctl -p




