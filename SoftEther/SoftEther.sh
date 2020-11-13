#!/bin/bash
# Author: MoeClub.org

export ADMIN=''
export USER=''
export PASSWD=''

while [[ $# -ge 1 ]]; do
  case $1 in
    -a)
      shift
      ADMIN=`echo "$1" |sed 's/[[:space:]]//g'`
      shift
      ;;
    -u)
      shift
      USER=`echo "$1" |sed 's/[[:space:]]//g'`
      shift
      ;;
    -p)
      shift
      PASSWD=`echo "$1" |sed 's/[[:space:]]//g'`
      shift
      ;;
    *)
      echo -ne " Usage:\n\tbash $(basename $0)\t-a [AdminPasswd] -u [User] -p [Passwd]\n"
      exit 1;
      ;;
    esac
  done

[ -n "$ADMIN" ] || ADMIN="empty"
[ -n "$USER" ] || USER="vpn"
[ -n "$PASSWD" ] || PASSWD="vpn"


kill -9 `ps -C "vpnserver" -o pid=` >/dev/null 2>&1
rm -rf /tmp/vpnserver
rm -rf /etc/softether
mkdir -p /etc/softether

wget --no-check-certificate --no-cache -4 -qO "/tmp/softether.tar.gz" "https://www.softether-download.com/files/softether/v4.34-9745-rtm-2020.04.05-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.34-9745-rtm-2020.04.05-linux-x64-64bit.tar.gz"
wget --no-check-certificate --no-cache -4 -qO "/etc/softether/vpn_server.config" "https://raw.githubusercontent.com/MoeClub/Note/master/SoftEther/vpn_server.config"


tar -zvxf /tmp/softether.tar.gz -C /tmp
cd /tmp/vpnserver
make i_read_and_agree_the_license_agreement
[ $? -eq 0 ] || exit 1


[ -f /tmp/vpnserver/vpnserver ] && cp -rf /tmp/vpnserver/vpnserver /etc/softether
[ -f /tmp/vpnserver/vpncmd ] && cp -rf /tmp/vpnserver/vpncmd /etc/softether
[ -f /tmp/vpnserver/hamcore.se2 ] && cp -rf /tmp/vpnserver/hamcore.se2 /etc/softether
[ -f /etc/softether/vpnserver ] && [ -f /etc/softether/vpncmd ] && [ -f /tmp/vpnserver/hamcore.se2 ] || exit 1
chmod -R 755 /etc/softether


if [ -f /etc/crontab ]; then
  sed -i '/vpnserver/d' /etc/crontab
  while [ -z "$(sed -n '$p' /etc/crontab)" ]; do sed -i '$d' /etc/crontab; done
  sed -i "\$a\@reboot root /etc/softether/vpnserver start >>/dev/null 2>&1 &\n\n\n" /etc/crontab
fi

/etc/softether/vpnserver start

while true; do /etc/softether/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:empty /CMD:About >/dev/null 2>&1; [ $? -eq 0 ] && break; echo "Waiting vpnserver ..."; sleep 1; done

/etc/softether/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:empty /HUB:DEFAULT /CMD:UserCreate "$USER" /GROUP: /REALNAME: /NOTE:
/etc/softether/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:empty /HUB:DEFAULT /CMD:UserPasswordSet "$USER" /PASSWORD:"$PASSWD"

/etc/softether/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:empty /HUB:DEFAULT /CMD:SetHubPassword "$ADMIN"
/etc/softether/vpncmd 127.0.0.1:5555 /SERVER /PASSWORD:empty /CMD:ServerPasswordSet "$ADMIN"

/etc/softether/vpnserver stop
/etc/softether/vpnserver start

