#!/bin/bash
# Script by MoeClub.org

[ $EUID -ne 0 ] && echo "Error:This script must be run as root!" && exit 1

os_ver="$(dpkg --print-architecture)"
[ -n "$os_ver" ] || exit 1
deb_ver="$(cat /etc/issue |grep -io 'Ubuntu.*\|Debian.*' |sed -r 's/(.*)/\L\1/' |grep -o '[0-9.]*')"
if [ "$deb_ver" == "7" ]; then
  ver='wheezy' && url='archive.debian.org' && urls='archive.debian.org'
elif [ "$deb_ver" == "8" ]; then
  ver='jessie' && url='archive.debian.org' && urls='deb.debian.org'
elif [ "$deb_ver" == "9" ]; then
  ver='stretch' && url='deb.debian.org' && urls='deb.debian.org'
else
  exit 1
fi

if [ "$deb_ver" == "9" ]; then
  bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/BBR/master/install.sh')
  wget --no-check-certificate -qO '/tmp/tcp_bbr.ko' 'https://moeclub.org/attachment/LinuxSoftware/bbr/tcp_bbr.ko'
  cp -rf /tmp/tcp_bbr.ko /lib/modules/4.14.153/kernel/net/ipv4
  sed -i '/^net\.core\.default_qdisc/d' /etc/sysctl.conf
  sed -i '/^net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
  while [ -z "$(sed -n '$p' /etc/sysctl.conf)" ]; do sed -i '$d' /etc/sysctl.conf; done
  sed -i '$a\net.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr\n\n' /etc/sysctl.conf
fi

echo "deb http://${url}/debian ${ver} main" >/etc/apt/sources.list
echo "deb-src http://${url}/debian ${ver} main" >>/etc/apt/sources.list
echo "deb http://${urls}/debian-security ${ver}/updates main" >>/etc/apt/sources.list
echo "deb-src http://${urls}/debian-security ${ver}/updates main" >>/etc/apt/sources.list

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y unzip p7zip-full gawk curl dnsmasq nload dnsutils iftop netcat
DEBIAN_FRONTEND=noninteractive apt-get install -y dbus init-system-helpers libc6 libev4  libgssapi-krb5-2 libhttp-parser2.1 liblz4-1 libnl-3-200 libnl-route-3-200 liboath0 libopts25 libpcl1 libprotobuf-c1 libsystemd0 libtalloc2 gnutls-bin ssl-cert 
DEBIAN_FRONTEND=noninteractive apt-get install -y ethtool
if [ "$deb_ver" != "9" ]; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y libgnutls-deb0-28 libnettle4
else
  DEBIAN_FRONTEND=noninteractive apt-get install -y ocserv
  DEBIAN_FRONTEND=noninteractive apt-get --fix-broken install
fi

mkdir -p /tmp
ifname=`cat /proc/net/dev |grep ":" |cut -d":" -f1| sed "s/[[:space:]]//g" |grep -v '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv' |head -n1`
[ -z "$ifname" ] && echo "Not found interface." && exit 1
PublicIP="$(wget --no-check-certificate -qO- http://checkip.amazonaws.com)"

command -v iftop >>/dev/null 2>&1
[[ $? -eq '0' ]] && {
cat >/root/.iftoprc<<EOF
interface: ${ifname}
dns-resolution: no
port-resolution: no
show-bars: yes
port-display: on
link-local: no
use-bytes: yes
sort: 2s
line-display: one-line-sent
show-totals: yes
log-scale: yes
EOF
}

[[ -f /etc/dnsmasq.conf ]] && {
cat >/etc/dnsmasq.conf<<EOF
except-interface=${ifname}
conf-dir=/etc/dnsmasq.d,*.conf
dhcp-range=192.168.8.2,192.168.8.254,255.255.255.0,24h
dhcp-option-force=option:router,192.168.8.1
dhcp-option-force=option:dns-server,192.168.8.1
dhcp-option-force=option:netbios-ns,192.168.8.1
listen-address=127.0.0.1,192.168.8.1
domain-needed
bind-dynamic
all-servers
bogus-priv
no-negcache
no-resolv
no-hosts
no-poll
cache-size=10000
server=208.67.220.220#5353

EOF
}

if [ "$deb_ver" != "9" ]; then
  wget --no-check-certificate -qO "/tmp/libradcli4_1.2.6-3~bpo8+1_${os_ver}.deb" "https://moeclub.org/attachment/DebianPackage/ocserv/libradcli4_1.2.6-3~bpo8+1_${os_ver}.deb"
  wget --no-check-certificate -qO "/tmp/ocserv_0.11.6-1~bpo8+2_${os_ver}.deb" "https://moeclub.org/attachment/DebianPackage/ocserv/ocserv_0.11.6-1~bpo8+2_${os_ver}.deb"
  dpkg -i /tmp/libradcli4_*.deb
  dpkg -i /tmp/ocserv_*.deb
fi
[ -e /etc/ocserv ] && rm -rf /etc/ocserv
mkdir -p /etc/ocserv
mkdir -p /etc/ocserv/group
mkdir -p /etc/ocserv/template

wget --no-check-certificate -qO "/etc/ocserv/group/Default" "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv/group/Default"
wget --no-check-certificate -qO "/etc/ocserv/group/NoRoute" "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv/group/NoRoute"
wget --no-check-certificate -qO "/etc/ocserv/group/Route" "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv/group/Route"
wget --no-check-certificate -qO "/etc//ocserv/template/ca.tmpl" "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv/template/ca.tmpl"
wget --no-check-certificate -qO "/etc/ocserv/template/user.tmpl" "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv/template/user.tmpl"
wget --no-check-certificate -qO "/etc/ocserv/template/client.sh" "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv/template/client.sh"
wget --no-check-certificate -qO "/etc/ocserv/iptables.rules" "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv/iptables.rules"
wget --no-check-certificate -qO "/etc/ocserv/ocserv.conf" "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv/ocserv.conf"
wget --no-check-certificate -qO "/etc/ocserv/ocserv.d" "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv/ocserv.d"
wget --no-check-certificate -qO "/etc/ocserv/profile.xml" "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv/profile.xml"

# Diffie-Hellman
certtool --generate-dh-params --outfile /etc/ocserv/dh.pem

# CA
openssl genrsa -out /etc/ocserv/template/ca-key.pem 2048
certtool --generate-self-signed --hash SHA256 --load-privkey /etc/ocserv/template/ca-key.pem --template /etc/ocserv/template/ca.tmpl --outfile /etc/ocserv/template/ca-cert.pem
cp -rf /etc/ocserv/template/ca-cert.pem /etc/ocserv/ca.cert.pem

# Server
# server cert file: /etc/ocserv/server.cert.pem
# server cert key file: /etc/ocserv/server.key.pem

# Default User
## openssl passwd Moeclub
echo "MoeClub:Default:zeGEF25ZQQfDo" >/etc/ocserv/ocpasswd

chown -R root:root /etc/ocserv
chmod -R a+x /etc/ocserv

[[ -f /etc/crontab ]] && [[ -f /etc/ocserv/iptables.rules ]] && {
  sed -i '/\/etc\/ocserv/d' /etc/crontab
  while [ -z "$(sed -n '$p' /etc/crontab)" ]; do sed -i '$d' /etc/crontab; done
  sed -i "\$a\@reboot root bash /etc/ocserv/iptables.rules\n" /etc/crontab
  sed -i "\$a\@reboot root bash /etc/ocserv/ocserv.d >>/dev/null 2>&1 &\n\n\n" /etc/crontab
}
[[ -f /etc/init.d/ocserv ]] && {
  sed -i 's/^#[[:space:]]*Required-Start:.*/# Required-Start:\t\$all/' /etc/init.d/ocserv
  sed -i 's/^#[[:space:]]*Required-Stop:.*/# Required-Stop:\t\$all/' /etc/init.d/ocserv
}
[[ -f /etc/ocserv/group/NoRoute ]] && sed -i 's/^no-route = .*\/255.255.255.255/no-route = '${PublicIP}'\/255.255.255.255/' /etc/ocserv/group/NoRoute
find /lib/systemd/system -name 'ocserv*' -delete

# Sysctl
sed -i '/^net\.ipv4\.ip_forward/d' /etc/sysctl.conf
while [ -z "$(sed -n '$p' /etc/sysctl.conf)" ]; do sed -i '$d' /etc/sysctl.conf; done
sed -i '$a\net.ipv4.ip_forward = 1\n\n' /etc/sysctl.conf

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

# SSH Ciphers
#[ -f /etc/ssh/sshd_config ] && sed -i "/^KexAlgorithms/d" /etc/ssh/sshd_config;
#echo "KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256" >>/etc/ssh/sshd_config;
#[ -f /etc/ssh/sshd_config ] && sed -i "/^Ciphers/d" /etc/ssh/sshd_config;
#echo "Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com" >>/etc/ssh/sshd_config;
#[ -f /etc/ssh/sshd_config ] && sed -i "/^MACs/d" /etc/ssh/sshd_config;
#echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com" >>/etc/ssh/sshd_config;


# Timezone
cp -f /usr/share/zoneinfo/PRC /etc/localtime
echo "Asia/Shanghai" >/etc/timezone

read -n 1 -p "Press <ENTER> to reboot..."
## Rebot Now
reboot
