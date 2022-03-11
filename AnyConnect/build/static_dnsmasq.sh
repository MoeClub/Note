#!/bin/bash

cd /tmp

wget --no-check-certificate -4 -O dnsmasq.tar.xz http://www.thekelleys.org.uk/dnsmasq/dnsmasq-2.86.tar.gz
[ -d dnsmasq ] && rm -rf dnsmasq
mkdir -p dnsmasq; tar -xvf dnsmasq.tar.xz -C dnsmasq --strip-components=1;
cd dnsmasq

# Disable IPv6
sed -i 's/^[[:space:]]*if (flags || ede == EDE_NOT_READY)[[:space:]]*$/      if (\!flags \&\& (gotname \& F_IPV6))\n        flags = F_NXDOMAIN;\n\n&/' ./src/forward.c

# Disable type 65
sed -i 's/^#define T_CAA.*/&\n#define T_HTTPS\t\t65/' ./src/dns-protocol.h
sed -i 's/^#define F_SRV.*/&\n#define F_HTTPS\t\t(1u<<31)/' ./src/dnsmasq.h
sed -i "$((`sed -n -e '/^[[:space:]]*if (qtype == T_AAAA)/=' ./src/rfc1035.c` + 1))s/return F_IPV6;/return F_IPV6;\n      if (qtype == T_HTTPS)\n  return F_HTTPS;/" ./src/rfc1035.c
sed -i 's/^[[:space:]]*if (flags || ede == EDE_NOT_READY)[[:space:]]*$/      if (\!flags \&\& (gotname \& F_HTTPS))\n        flags = F_NXDOMAIN;\n\n&/' ./src/forward.c


make CFLAGS="-I. -Wall -W -fPIC -O2" LDFLAGS="-L. -static -s"
make PREFIX=/usr DESTDIR=/tmp install
