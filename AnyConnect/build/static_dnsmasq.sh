#!/bin/bash

cd /tmp

wget --no-check-certificate -4 -O dnsmasq.tar.xz http://www.thekelleys.org.uk/dnsmasq/dnsmasq-2.82.tar.xz
[ -d dnsmasq ] && rm -rf dnsmasq
mkdir -p dnsmasq; tar -xJ -f dnsmasq.tar.xz -C dnsmasq --strip-components=1;
cd dnsmasq

make CFLAGS="-I. -Wall -W -fPIC -O2" LDFLAGS="-L. -static -s"
make PREFIX="/usr" DESTDIR=.. install

