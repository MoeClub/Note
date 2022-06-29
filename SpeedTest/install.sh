
#!/bin/bash

case `uname -m` in aarch64|arm64) arch="arm64";; x86_64|amd64) arch="amd64";; *) arch="";; esac
[ -n "$arch" ] || exit 1

systemctl stop speedtest.service >/dev/null 2>&1
systemctl disable speedtest.service >/dev/null 2>&1

rm -rf /etc/speedtest
mkdir -p /etc/speedtest

cat >/etc/speedtest/speedtest.service<<EOF
[Unit]
Description=SpeedTest Service
After=network-online.target

[Service]
Type=simple
ExecStart=/etc/speedtest/speedtest
RestartSec=3s
Restart=always

[Install]
WantedBy=multi-user.target

EOF

wget --no-check-certificate --no-cache -4 -qO /etc/speedtest/speedtest "https://raw.githubusercontent.com/MoeClub/Note/master/SpeedTest/build/linux_${arch}/speedtest"

chmod -R 755 /etc/speedtest
cp -rf /etc/speedtest/speedtest.service /etc/systemd/system/
systemctl daemon-reload >/dev/null 2>&1
systemctl enable speedtest.service >/dev/null 2>&1
systemctl start speedtest.service >/dev/null 2>&1


