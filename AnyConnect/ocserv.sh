#!/bin/bash
# Script by MoeClub.org

[ $EUID -ne 0 ] && echo "Error:This script must be run as root!" && exit 1
EthName=`cat /proc/net/dev |grep ':' |cut -d':' -f1 |sed 's/\s//g' |grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn' |sed -n '1p'`
[ -n "$EthName" ] || exit 1

command -v yum >>/dev/null 2>&1
if [ $? -eq 0 ]; then
  yum install -y curl wget nc xz openssl gnutls-utils
else
  apt-get install -y curl wget netcat openssl gnutls-bin xz-utils
fi

XCMDS=("wget" "tar" "xz" "nc" "openssl" "certtool")
for XCMD in "${XCMDS[@]}"; do command -v "$XCMD" >>/dev/null 2>&1; [ $? -ne 0 ] && echo "Not Found $XCMD."; done

osVer="$(dpkg --print-architecture 2>/dev/null)"
if [ -n "$osVer" -a "$osVer" == "amd64" ]; then
  debVer="$(cat /etc/issue |grep -io 'Debian.*' |sed -r 's/(.*)/\L\1/' |grep -o '[0-9.]*')"
  if [ "$debVer" == "9" ]; then
    bash <(wget --no-check-certificate -4 -qO- 'https://raw.githubusercontent.com/MoeClub/apt/master/bbr/bbr.sh') 0 0
  fi
fi


mkdir -p /tmp
PublicIP="$(wget --no-check-certificate -4 -qO- http://checkip.amazonaws.com)"

# vlmcs
rm -rf /etc/vlmcs
wget --no-check-certificate -4 -qO /tmp/vlmcs.tar 'https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/vlmcsd/vlmcsd.tar'
tar --overwrite -xvf /tmp/vlmcs.tar -C /
[ -f /etc/vlmcs/vlmcs.d ] && bash /etc/vlmcs/vlmcs.d init

# dnsmasq
rm -rf /etc/dnsmasq.d
wget --no-check-certificate -4 -qO /tmp/dnsmasq.tar 'https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/build/dnsmasq_v2.82.tar'
tar --overwrite -xvf /tmp/dnsmasq.tar -C /
sed -i "s/#\?except-interface=.*/except-interface=${EthName}/" /etc/dnsmasq.conf

if [ -f /etc/crontab ]; then
  sed -i '/dnsmasq/d' /etc/crontab
  while [ -z "$(sed -n '$p' /etc/crontab)" ]; do sed -i '$d' /etc/crontab; done
  sed -i "\$a\@reboot root /usr/sbin/dnsmasq >>/dev/null 2>&1 &\n\n\n" /etc/crontab
fi

# ocserv
rm -rf /etc/ocserv
wget --no-check-certificate -4 -qO /tmp/ocserv.tar 'https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/build/ocserv_v0.12.3.tar'
tar --overwrite -xvf /tmp/ocserv.tar -C /

# server cert key file: /etc/ocserv/server.key.pem
openssl genrsa -out /etc/ocserv/server.key.pem 2048
# server cert file: /etc/ocserv/server.cert.pem
openssl req -new -x509 -days 3650 -key /etc/ocserv/server.key.pem -out /etc/ocserv/server.cert.pem -subj "/C=/ST=/L=/O=/OU=/CN=${PublicIP}"

# Default User
echo "MoeClub:Default:$(openssl passwd MoeClub)" >/etc/ocserv/ocpasswd

bash /etc/ocserv/template/client.sh

chown -R root:root /etc/ocserv
chmod -R 755 /etc/ocserv

[ -d /lib/systemd/system ] && find /lib/systemd/system -name 'ocserv*' -delete

if [ -f /etc/crontab ]; then
  sed -i '/\/etc\/ocserv/d' /etc/crontab
  while [ -z "$(sed -n '$p' /etc/crontab)" ]; do sed -i '$d' /etc/crontab; done
  sed -i "\$a\@reboot root bash /etc/ocserv/ocserv.d >>/dev/null 2>&1 &\n\n\n" /etc/crontab
fi

# Sysctl
if [ -f /etc/sysctl.conf ]; then
  sed -i '/^net\.ipv4\.ip_forward/d' /etc/sysctl.conf
  while [ -z "$(sed -n '$p' /etc/sysctl.conf)" ]; do sed -i '$d' /etc/sysctl.conf; done
  sed -i '$a\net.ipv4.ip_forward = 1\n\n' /etc/sysctl.conf
fi

# Limit
if [[ -f /etc/security/limits.conf ]]; then
  LIMIT='262144'
  sed -i '/^\(\*\|root\).*\(hard\|soft\).*\(memlock\|nofile\)/d' /etc/security/limits.conf
  while [ -z "$(sed -n '$p' /etc/security/limits.conf)" ]; do sed -i '$d' /etc/security/limits.conf; done
  echo -ne "*\thard\tnofile\t${LIMIT}\n*\tsoft\tnofile\t${LIMIT}\nroot\thard\tnofile\t${LIMIT}\nroot\tsoft\tnofile\t${LIMIT}\n" >>/etc/security/limits.conf
  echo -ne "*\thard\tmemlock\t${LIMIT}\n*\tsoft\tmemlock\t${LIMIT}\nroot\thard\tmemlock\t${LIMIT}\nroot\tsoft\tmemlock\t${LIMIT}\n\n\n" >>/etc/security/limits.conf
fi

# SSH
#[ -f /etc/ssh/sshd_config ] && sed -i "s/^#\?Port .*/Port 9527/g" /etc/ssh/sshd_config;
[ -f /etc/ssh/sshd_config ] && sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config;
[ -f /etc/ssh/sshd_config ] && sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config;

# Timezone
cp -f /usr/share/zoneinfo/PRC /etc/localtime
echo "Asia/Shanghai" >/etc/timezone

read -n 1 -p "Press <ENTER> to reboot..."
## Rebot Now
reboot
