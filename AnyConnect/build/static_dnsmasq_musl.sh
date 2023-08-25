#!/bin/bash


export version_dnsmasq=2.89

BUILD(){

  ARCH="${1:-}"

  command -v "${ARCH}-linux-musl-gcc" >/dev/null 2>&1
  [ $? -eq 0 ] || return 1

  export CC="${ARCH}-linux-musl-gcc"

  cd /tmp
  rm -rf dnsmasq-build
  mkdir -p dnsmasq-build

  wget --no-check-certificate -4 -O dnsmasq.tar.gz "http://www.thekelleys.org.uk/dnsmasq/dnsmasq-${version_dnsmasq}.tar.gz"
  [ -d dnsmasq ] && rm -rf dnsmasq
  mkdir -p dnsmasq; tar -xvf dnsmasq.tar.gz -C dnsmasq --strip-components=1;
  cd dnsmasq

  make CFLAGS="-I. -Wall -W -fPIC -O2" LDFLAGS="-L. -static -s"
  make PREFIX=/usr DESTDIR=/tmp/dnsmasq-build install

  cd /tmp/dnsmasq-build
  case "${ARCH}" in aarch64|arm64) arch="arm64";; x86_64|amd64) arch="amd64";; *) arch="unknown";; esac
  tar -cvf "../dnsmasq_${arch}_v${version_dnsmasq}.tar" ./
}


archArray=("x86_64" "aarch64")
for arch in "${archArray[@]}"; do
  BUILD "$arch"
done

