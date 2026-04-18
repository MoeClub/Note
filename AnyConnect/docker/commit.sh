#!/bin/sh

ocVer="${1:-1.4.1}"
dnsVer="${2:-2.92}"

apk add wget iproute2 openssl iptables
wget -qO- https://raw.githubusercontent.com/MoeClub/Note/refs/heads/master/AnyConnect/build/update.sh |sh -s "${ocVer}" "${dnsVer}"
mkdir -p /etc/dnsmasq.d /etc/ocserv/group
cp -rf /mnt/Default /etc/ocserv/group
cp -rf /mnt/NoRoute /etc/ocserv/group
cp -rf /mnt/ocserv.conf /etc/ocserv
cp -rf /mnt/dnsmasq.conf /etc/dnsmasq.conf
cp -rf /mnt/run.sh /run.sh
chmod -R 777 /etc/dnsmasq.d /etc/ocserv /run.sh
find /var -type f -delete
echo >$HOME/.ash_history


# docker rm -f alpine >/dev/null 2>&1; docker run --name alpine -it -v /mnt:/mnt alpine:3.20 /bin/sh /mnt/commit.sh
# docker commit --change 'CMD ["/bin/sh", "/run.sh"]' alpine ocserv:latest
# docker run --privileged --rm -it -p 8123:443 ocserv /bin/sh
# docker ps -aq |xargs docker rm -f
# docker images -aq |xargs docker rmi -f
