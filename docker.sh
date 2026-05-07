#!/bin/bash

dockerVer="${1:-20.10.24}"
composeVer="${2:-2.39.2}"

rm -rf /usr/bin/docker-init
rm -rf /usr/bin/containerd
rm -rf /usr/bin/ctr
rm -rf /usr/bin/runc
rm -rf /usr/bin/dockerd
rm -rf /usr/bin/docker-proxy
rm -rf /usr/bin/containerd-shim
rm -rf /usr/bin/docker
rm -rf /usr/bin/containerd-shim-runc-v2
rm -rf /etc/systemd/system/docker.service
rm -rf /var/lib/docker
rm -rf /etc/docker
rm -rf /usr/local/lib/docker
ps -C dockerd -o pid= |xargs kill -9 >/dev/null 2>&1
[ "$dockerVer" == "0" ] && exit 0


case `uname -m` in aarch64|arm64) arch="aarch64";; x86_64|amd64) arch="x86_64";; *) arch="";; esac
[ -n "$arch" ] || exit 1


wget --no-check-certificate -4 -qO- "https://download.docker.com/linux/static/stable/${arch}/docker-${dockerVer}.tgz" |tar -xzv --strip-components=1 -C /usr/bin
[ $? -eq 0 ] || exit 1
mkdir -p /usr/local/lib/docker/cli-plugins
wget --no-check-certificate -4 -qO "/usr/local/lib/docker/cli-plugins/docker-compose" "https://github.com/docker/compose/releases/download/v${composeVer}/docker-compose-linux-${arch}"
[ $? -eq 0 ] || exit 1
chmod -R 777 /usr/local/lib/docker/cli-plugins

cat >/etc/systemd/system/docker.service<<EOF
[Unit]
Description=docker
After=local-fs.target network.target

[Service]
Type=simple
ExecStart=/usr/bin/dockerd --log-driver=json-file --log-opt max-size=10m --log-opt max-file=2
KillMode=process
KillSignal=SIGINT
TimeoutStopSec=3
Restart=always
RestartSec=1s

[Install]
WantedBy=multi-user.target

EOF

systemctl disable docker 2>/dev/null
systemctl daemon-reload
systemctl enable docker
systemctl restart docker

