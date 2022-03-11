#!/bin/bash

cd /tmp

wget --no-check-certificate -4 -O dnsmasq.tar.xz http://www.thekelleys.org.uk/dnsmasq/dnsmasq-2.86.tar.xz
[ -d dnsmasq ] && rm -rf dnsmasq
mkdir -p dnsmasq; tar -xJ -f dnsmasq.tar.xz -C dnsmasq --strip-components=1;
cd dnsmasq

# Disable IPv6
sed -i 's/^[[:space:]]*if \(flags \|\| ede == EDE_NOT_READY\)/      if \(!flags \&\& \(gotname \& F_IPV6\)\)\n      	flags = F_NXDOMAIN;\n\n&/' ./src/forward.c

make CFLAGS="-I. -Wall -W -fPIC -O2" LDFLAGS="-L. -static -s"
make PREFIX=/usr DESTDIR=/tmp install
