#!/bin/sh

PORT="${1:-1080}"
USER="${2:-}"
PASSWORD="${3:-}"


WORK=`mktemp -d`
trap "rm -rf ${WORK}" EXIT

case `uname -m` in aarch64|arm64) arch="arm64";; x86_64|amd64) arch="amd64";; *) arch="";; esac
[ -n "$arch" ] || exit 1

[ -f ./wireproxy ] && cp ./wireproxy "${WORK}" || curl -sSL "https://api.github.com/repos/pufferffish/wireproxy/releases/latest" |grep "browser_download_url" |grep "linux" |grep "${arch}" |cut -d'"' -f4 |xargs curl -sSL |tar -zx -C "${WORK}"
[ $? -eq 0 ] || exit 1
[ -f ./wgcf ] && cp ./wgcf "${WORK}" || curl -sSL "https://api.github.com/repos/ViRb3/wgcf/releases/latest" |grep "browser_download_url" |grep "linux" |grep "${arch}" |cut -d'"' -f4 |xargs curl -sSL -o "${WORK}/wgcf"
[ $? -eq 0 ] || exit 1

chmod -R 777 "${WORK}"
cd "${WORK}"

./wgcf register --config ./wgcf-account.toml --accept-tos >/dev/null 2>&1
./wgcf generate --config ./wgcf-account.toml -p ./wgcf-profile.conf >/dev/null 2>&1

cat >"./wireproxy.conf"<< EOF
[Interface]
`cat ./wgcf-profile.conf |grep '^PrivateKey'`
`cat ./wgcf-profile.conf |grep '^Address'`
DNS = 8.8.8.8,8.8.4.4,2001:4860:4860::8888,2001:4860:4860::8844
`cat ./wgcf-profile.conf |grep '^MTU'`
[Peer]
`cat ./wgcf-profile.conf |grep '^PublicKey'`
AllowedIPs = ::/0
Endpoint = [2606:4700:d0::a29f:c001]:2408
[Peer]
`cat ./wgcf-profile.conf |grep '^PublicKey'`
AllowedIPs = 0.0.0.0/0
Endpoint = 162.159.192.1:2408

[Socks5]
BindAddress = 0.0.0.0:${PORT}
`[ -n "${USER}" ] && [ -n "${PASSWORD}" ] && echo -en "Username = ${USER}\nPassword = ${PASSWORD}"`

EOF

./wireproxy -c "./wireproxy.conf"



