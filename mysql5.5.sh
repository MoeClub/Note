#!/bin/bash

MySQLRoot="/usr/local/mysql"

apt install -y libaio1 libncurses5 wget

systemctl stop mysql >/dev/null 2>&1
bash /etc/init.d/mysql.server stop >/dev/null 2>&1

rm -rf /var/lib/mysql
rm -rf /etc/mysql
rm -rf /etc/my.cnf
rm -rf /etc/init.d/mysql.server 
rm -rf /usr/local/bin/mysql
rm -rf "$MySQLRoot"

groupadd mysql
useradd -g mysql mysql

rm -rf /usr/local/mysql
mkdir -p /usr/local/mysql
wget -qO- https://downloads.mysql.com/archives/get/p/23/file/mysql-5.5.62-linux-glibc2.12-x86_64.tar.gz |tar -zxv --strip-components=1 -C "$MySQLRoot"
chown -R mysql:mysql "$MySQLRoot"

cd "$MySQLRoot"
"$MySQLRoot/scripts/mysql_install_db" --user=mysql

chown -R root:root "$MySQLRoot"
chown -R mysql:mysql "$MySQLRoot/data"

cp -rf "$MySQLRoot/support-files/mysql.server" /etc/init.d/mysql.server
cp -rf "$MySQLRoot/support-files/my-medium.cnf" /etc/my.cnf
sed -i '/^bind-address/d' /etc/my.cnf
sed -i 's/\[mysqld\]/\[mysqld\]\nbind-address = 127.0.0.1/' /etc/my.cnf

"$MySQLRoot/bin/mysqld_safe" --user=mysql >/dev/null &
sleep 10

"$MySQLRoot/bin/mysqladmin" -u root password ""
"$MySQLRoot/bin/mysql" -uroot -Dmysql -e 'DELETE FROM user WHERE Host<>"localhost" OR User=""; FLUSH privileges;'

ln -sf "$MySQLRoot/bin/mysql" /usr/local/bin/mysql

update-rc.d -f mysql.server remove
update-rc.d -f mysql.server defaults
