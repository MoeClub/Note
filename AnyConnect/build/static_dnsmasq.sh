#!/bin/bash

cd /tmp

wget --no-check-certificate -4 -O dnsmasq.tar.xz http://www.thekelleys.org.uk/dnsmasq/dnsmasq-2.86.tar.xz
[ -d dnsmasq ] && rm -rf dnsmasq
mkdir -p dnsmasq; tar -xJ -f dnsmasq.tar.xz -C dnsmasq --strip-components=1;
cd dnsmasq

# Disable IPv6
sed -i "$((`sed -n -e '/^[[:space:]]*if (qtype == T_AAAA)/=' ./src/rfc1035.c` + 1))s/return F_IPV6;/return 0;\n      if \(qtype == 65\)\n	return 0;/" ./src/rfc1035.c

make CFLAGS="-I. -Wall -W -fPIC -O2" LDFLAGS="-L. -static -s"
make PREFIX=/usr DESTDIR=/tmp install
