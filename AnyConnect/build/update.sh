#!/bin/sh

oVer="${1:-0}"
dVer="${2:-0}"

case `uname -m` in aarch64|arm64) arch="aarch64";; x86_64|amd64) arch="x86_64";; *) arch="";; esac
[ -n "$arch" ] || exit 1

if [ "$oVer" != "0" ]; then
  ocservFile="ocserv_${arch}_v${oVer}.tar.gz"
  [ -f "./${ocservFile}" ] || {
    wget -qO "${ocservFile}" "https://github.com/MoeClub/Note/raw/refs/heads/master/AnyConnect/build/ocserv_${arch}_v${oVer}.tar.gz"
    trapFile="${ocservFile}"
    trap "rm -rf ${trapFile}" EXIT
    [ $? -eq 0 ] || exit 1
  }

  rm -rf /usr/bin/occtl
  rm -rf /usr/bin/ocpasswd
  rm -rf /usr/bin/ocserv-fw
  rm -rf /usr/libexec/ocserv-fw
  rm -rf /usr/sbin/ocserv
  rm -rf /usr/sbin/ocserv-worker
  rm -rf /usr/share/man/man8/occtl.8
  rm -rf /usr/share/man/man8/ocpasswd.8
  rm -rf /usr/share/man/man8/ocserv.8

  tar --overwrite -xvf "${ocservFile}" -C /

  systemctl restart ocserv
  ocserv -v
fi

if [ "$dVer" != "0" ]; then
  dnsmasqFile="dnsmasq_${arch}_v${dVer}.tar.gz"
  [ -f "./${dnsmasqFile}" ] || {
    wget -qO "${dnsmasqFile}" "https://github.com/MoeClub/Note/raw/refs/heads/master/AnyConnect/build/dnsmasq_${arch}_v${dVer}.tar.gz"
    trapFile="${trapFile} ${dnsmasqFile}"
    trap "rm -rf ${trapFile}" EXIT
    [ $? -eq 0 ] || exit 1
  }

  rm -rf /usr/sbin/dnsmasq
  rm -rf /usr/share/man/man8/dnsmasq.8

  tar --overwrite -xvf "${dnsmasqFile}" -C /

  systemctl restart dnsmasq
  dnsmasq -v
fi

