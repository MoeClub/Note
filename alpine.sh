#!/bin/sh

PORT="${1:-22}"
PASS="${2:-Vicer}"

[ `whoami` == "root" ] || exit 1

echo "remote" >/etc/hostname
echo "root:${PASS}" |chpasswd root
sed -i "s/^#\?Port.*/Port $PORT/g" /etc/ssh/sshd_config;
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
sed -i 's/^#\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/g' /etc/ssh/sshd_config;
[ -d /etc/ssh/sshd_config.d ] && rm -rf /etc/ssh/sshd_config.d/*
systemctl restart sshd 2>/dev/null || /etc/init.d/sshd restart

[ -e /usr/share/zoneinfo/Asia/Shanghai ] && {
  cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  echo "Asia/Shanghai" > /etc/timezone
}

for usr in `cat /etc/passwd |cut -d':' -f1,6`; do
  u=`echo "$usr" |cut -d':' -f1`
  h=`echo "$usr" |cut -d':' -f2`
  echo "$h" |grep -q '^/home' && {
  	deluser "$u" 2>/dev/null
  	rm -rf "$h" 2>/dev/null
  }
done

exit 0
