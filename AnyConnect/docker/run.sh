#!/bin/sh

[ ! -e "/dev/net/tun" ] && echo "try with --privileged " && exit 1
device=`ls -1 /sys/class/net| grep -v '^lo$' |head -n 1`
[ -n "$device" ] || exit 1
addr=`wget -qO- https://checkip.amazonaws.com/`
[ -n "$addr" ] || addr=`ip -4 addr show "$net" | awk '/inet /{print $2}' | cut -d/ -f1`


ocPath=`find /mnt -type f -name "ocserv.conf"`
[ -n "$ocPath" ] && ocDir=`dirname "$ocPath"` || ocDir=""
[ -n "$ocDir" ] && ln -sf "$ocDir" "/etc/ocserv"

dnsPath=`find /mnt -type f -name "dnsmasq.conf"`
[ -n "$dnsPath" ] && cp -rf "$dnsPath" "/etc/dnsmasq.conf"
[ -d "/mnt/dnsmasq.d" ] && ln -sf "/mnt/dnsmasq.d" "/etc/dnsmasq.d"

[ -f "/etc/ocserv/group/NoRoute" ] && sed -i "s/^no-route =.*\/255\.255\.255\.255/no-route = ${addr}\/255.255.255.255/" "/etc/ocserv/group/NoRoute"
[ -f "/etc/ocserv/ocpasswd" ] || {
  for gp in `find /etc/ocserv/group -type f 2>/dev/null`; do
    gn=`basename "$gp"`
    user=`openssl rand -base64 32 | tr -dc 'a-z' | head -c 3`
    passwd=`openssl rand -base64 32 | tr -dc 'a-z' | head -c 3`
    encpwd=`openssl passwd "${passwd}"`
    echo -ne "${gn}--> ${user}:${passwd}\n"
    echo -ne "${user}:${gn}:${encpwd}\n" >>/etc/ocserv/ocpasswd
  done
}

[ -f "/etc/ocserv/ca.key.pem" ] || openssl req -x509 -sha256 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 3650 -subj "/C=/ST=/L=/OU=/O=/CN=${addr} CA" -addext "keyUsage=critical, keyCertSign, cRLSign" -rand /dev/urandom -outform PEM -keyout "/etc/ocserv/ca.key.pem" -out "/etc/ocserv/ca.crt.pem" >/dev/null 2>&1
[ -f "/etc/ocserv/server.key.pem" ] && [ -f "/etc/ocserv/server.crt.pem" ] || openssl req -x509 -sha256 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 3650 -subj "/C=/ST=/L=/OU=/O=/CN=${addr}" -config <(echo -e "[ req ]\ndistinguished_name=req\n") -addext "basicConstraints=CA:FALSE" -addext "keyUsage=critical, digitalSignature, keyEncipherment" -addext "extendedKeyUsage=serverAuth, clientAuth" -rand /dev/urandom -outform PEM -keyout "/etc/ocserv/server.key.pem" -out "/etc/ocserv/server.crt.pem" >/dev/null 2>&1

tcp=`cat "/etc/ocserv/ocserv.conf" |grep '^#\?tcp-port' |cut -d"=" -f2 |grep -o '[0-9]*' |head -n1`
udp=`cat "/etc/ocserv/ocserv.conf" |grep '^#\?udp-port' |cut -d"=" -f2 |grep -o '[0-9]*' |head -n1`
net=`cat "/etc/ocserv/ocserv.conf" |grep '^ipv4-network' |cut -d"=" -f2 |grep -o '[0-9\.]*' |head -n1`

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o "${device}" -j MASQUERADE
iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
[ -n "${net}" ] && iptables -I FORWARD -d "${net}/24" -j ACCEPT
[ -n "${net}" ] && iptables -I FORWARD -s "${net}/24" -j ACCEPT
[ -n "${net}" ] && iptables -I OUTPUT -d "${net}/24" -j ACCEPT
[ -n "${net}" ] && iptables -I INPUT -s "${net}/24" -j ACCEPT
[ -n "${tcp}" ] && [ "$tcp" -gt "0" ] && iptables -I INPUT -p tcp --dport "${tcp}" -j ACCEPT
[ -n "${udp}" ] && [ "$udp" -gt "0" ] && iptables -I INPUT -p udp --dport "${udp}" -j ACCEPT

[ -f "/etc/dnsmasq.conf" ] && {
  sed -i "s/^except-interface=.*/except-interface=${device}/" "/etc/dnsmasq.conf"
  [ -n "${net}" ] && dnsnet="$(echo ${net} |cut -d. -f1-3)" || dnsnet=""
  [ -n "${dnsnet}" ] && {
    sed -i "s/^dhcp-range=.*/dhcp-range=${dnsnet}.2,${dnsnet}.254,255.255.255.0,24h/" "/etc/dnsmasq.conf"
    sed -i "s/^dhcp-option-force=option:router,.*/dhcp-option-force=option:router,${dnsnet}.1/" "/etc/dnsmasq.conf"
    sed -i "s/^dhcp-option-force=option:dns-server,.*/dhcp-option-force=option:dns-server,${dnsnet}.1/" "/etc/dnsmasq.conf"
    sed -i "s/^dhcp-option-force=option:netbios-ns,.*/dhcp-option-force=option:netbios-ns,${dnsnet}.1/" "/etc/dnsmasq.conf"
    sed -i "s/^listen-address=.*/listen-address=127.0.0.1,${dnsnet}.1/" "/etc/dnsmasq.conf"
    sed -i "s/^srv-host=_vlmcs._tcp,.*/srv-host=_vlmcs._tcp,${dnsnet}.1,1688,0,100/" "/etc/dnsmasq.conf"
    sed -i "s/^srv-host=_vlmcs._tcp.lan,.*/srv-host=_vlmcs._tcp.lan,${dnsnet}.1,1688,0,100/" "/etc/dnsmasq.conf"
    sed -i "s/^srv-host=_vlmcs._tcp.srv,.*/srv-host=_vlmcs._tcp.srv,${dnsnet}.1,1688,0,100/" "/etc/dnsmasq.conf"
  }
}

/usr/sbin/dnsmasq -d -q 2>&1 &
/usr/sbin/ocserv --foreground --config /etc/ocserv/ocserv.conf

