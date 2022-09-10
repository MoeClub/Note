#!/bin/bash

case `uname -m` in aarch64|arm64) ARCH="arm64";; x86_64|amd64) ARCH="amd64";; *) ARCH="";; esac
[ -n "$ARCH" ] || exit 1

systemctl stop qBittorrent.service >/dev/null 2>&1
systemctl disable qBittorrent.service >/dev/null 2>&1
systemctl stop qbt.service >/dev/null 2>&1
systemctl disable qbt.service >/dev/null 2>&1
rm -rf /usr/bin/qbittorrent

URL="https://github.com/MoeClub/Note/raw/master/qBittorrent"

wget --no-check-certificate -4 -qO- "${URL}/bin/qbittorrent_${ARCH}_v4.4.2_lt_v2.0.6.tar.xz" |tar -Jxv -C /usr/bin
[ $? -eq 0 ] || exit 1

strip /usr/bin/qbittorrent >/dev/null 2>&1
chmod 777 /usr/bin/qbittorrent
mkdir -p /home/qBittorrent/config
mkdir -p /home/qBittorrent/downloads

wget --no-check-certificate -4 -qO- "${URL}/qBittorrent.conf" >/home/qBittorrent/config/qBittorrent.conf
wget --no-check-certificate -4 -qO- "${URL}/qBittorrent.service" >/etc/systemd/system/qbt.service

systemctl daemon-reload >/dev/null 2>&1
systemctl enable qbt.service >/dev/null 2>&1
systemctl start qbt.service >/dev/null 2>&1
systemctl status qbt.service




