#!/bin/bash

case `uname -m` in aarch64|arm64) ARCH="arm64";; x86_64|amd64) ARCH="amd64";; *) ARCH="";; esac
[ -n "$ARCH" ] || exit 1

URL="https://github.com/MoeClub/Note/raw/master/Aria2"

systemctl stop aria2.service >/dev/null 2>&1
systemctl disable aria2.service >/dev/null 2>&1
rm -rf /usr/bin/aria2c


wget --no-check-certificate -4 -qO- "${URL}/aria2c_${ARCH}_v1.36.0.tar.gz" |tar -zxv -C /usr/bin
[ $? -eq 0 ] || exit 1

strip /usr/bin/aria2c >/dev/null 2>&1
chmod 777 /usr/bin/aria2c

mkdir -p /etc/aria2
wget --no-check-certificate -4 -qO- "${URL}/aria2.conf" >/etc/aria2/aria2.conf

cat >/etc/systemd/system/aria2.service<<EOF
[Unit]
Description=Aria2c Daemon Service
After=network.target


[Service]
Type=simple
ExecStart=/usr/bin/aria2c --conf-path=/etc/aria2/aria2.conf
ExecStop=/usr/bin/kill -9 \$MAINPID
Restart=always
LimitNOFILE=262144
TimeoutSec=300


[Install]
WantedBy=multi-user.target

EOF


systemctl daemon-reload >/dev/null 2>&1
systemctl enable aria2.service >/dev/null 2>&1
systemctl start aria2.service >/dev/null 2>&1
systemctl status aria2.service

