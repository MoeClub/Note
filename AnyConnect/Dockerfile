FROM debian

RUN apt-get update && apt-get install -y wget procps systemd iproute2 openssl iptables

RUN /usr/bin/wget --no-check-certificate --no-cache -4 -qO /tmp/ocserv.deb "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv.deb" && /usr/bin/dpkg -i /tmp/ocserv.deb && /bin/rm -rf /tmp/ocserv.deb

RUN /bin/bash /etc/ocserv/ctl.sh

RUN /bin/bash -c "ip route show default |head -n1 |sed 's/.*dev\s*\([0-9a-zA-Z]\+\).*/\1/g' |xargs -I {} sed -i 's/^except-interface=.*/except-interface={}/' /etc/dnsmasq.conf"

CMD ["/bin/bash", "-c", "[ -n $PASSWD ] && bash /etc/ocserv/ctl.sh PASSWD $PASSWD; /usr/sbin/dnsmasq && bash /etc/ocserv/ctl.sh && /usr/sbin/ocserv --config /etc/ocserv/ocserv.conf -f"]

