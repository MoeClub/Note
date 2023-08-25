#!/bin/bash

wget -O /tmp/ocserv.deb https://github.com/MoeClub/Note/raw/master/AnyConnect/build/ocserv.deb
[ "$?" -eq 0 ] || exit 1


mv /etc/dnsmasq.d /etc/dnsmasq.d.bak
mv /etc/ocserv /etc/ocserv.bak
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak

dpkg -i /tmp/ocserv.deb
rm -rf /etc/ocserv /etc/dnsmasq.d /etc/dnsmasq.conf

mv /etc/dnsmasq.d.bak /etc/dnsmasq.d
mv /etc/ocserv.bak /etc/ocserv
mv /etc/dnsmasq.conf.bak /etc/dnsmasq.conf

systemctl restart dnsmasq
systemctl restart ocserv

ocserv -v
dnsmasq -v
