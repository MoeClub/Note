#!/bin/sh

ver="${1:-1.4.0}"

case `uname -m` in aarch64|arm64) arch="aarch64";; x86_64|amd64) arch="x86_64";; *) arch="";; esac
[ -n "$arch" ] || exit 1

tarfile=`mktemp -u`
wget -qO "${tarfile}" "https://github.com/MoeClub/Note/raw/refs/heads/master/AnyConnect/build/ocserv_${arch}_v${ver}.tar.gz"
[ $? -eq 0 ] || exit 1

tar --overwrite -xvf "${tarfile}" -C /

rm -rf /usr/bin/occtl
rm -rf /usr/bin/ocpasswd
rm -rf /usr/bin/ocserv-fw
rm -rf /usr/libexec/ocserv-fw
rm -rf /usr/sbin/ocserv
rm -rf /usr/sbin/ocserv-worker
rm -rf /usr/share/man/man8/occtl.8
rm -rf /usr/share/man/man8/ocpasswd.8
rm -rf /usr/share/man/man8/ocserv.8

systemctl restart ocserv
ocserv -v
