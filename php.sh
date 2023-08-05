#!/bin/bash

case `uname -m` in aarch64|arm64) arch="aarch64";; x86_64|amd64) arch="x86-64";; *) arch="";; esac
[ -n "$arch" ] || exit 1;

phpVer=${1:-5.6}

apt-get install -y gnupg2 ca-certificates lsb-release apt-transport-https
apt-key add <(wget -qO- https://packages.sury.org/php/apt.gpg)
rm -rf /etc/apt/sources.list.d/php.list
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" |tee /etc/apt/sources.list.d/php.list
apt update

apt-get install -y "php${phpVer}" "php${phpVer}-cli" "php${phpVer}-common" "php${phpVer}-fpm" "php${phpVer}-xml" "php${phpVer}-gd" "php${phpVer}-mysql" "php${phpVer}-imap" "php${phpVer}-curl"
update-alternatives --set php "/usr/bin/php${phpVer}"


sed -i 's/^listen[[:space:]]*=.*/listen = 127.0.0.1:9000/' "/etc/php/${phpVer}/fpm/pool.d/www.conf"
sed -i 's/^;\?pm\.max_children[[:space:]]*=.*/pm\.max_children = 32/' "/etc/php/${phpVer}/fpm/pool.d/www.conf"

sed -i 's/^;\?emergency_restart_threshold[[:space:]]*=.*/emergency_restart_threshold = 5/' "/etc/php/${phpVer}/fpm/php-fpm.conf"
sed -i 's/^;\?emergency_restart_interval[[:space:]]*=.*/emergency_restart_interval = 300/' "/etc/php/${phpVer}/fpm/php-fpm.conf"
sed -i 's/^;\?process_control_timeout[[:space:]]*=.*/process_control_timeout = 180/' "/etc/php/${phpVer}/fpm/php-fpm.conf"

sed -i 's/^;\?date\.timezone[[:space:]]*=.*/date\.timezone = \"Asia\/Shanghai\"/' "/etc/php/${phpVer}/cli/php.ini"
sed -i 's/^;\?date\.timezone[[:space:]]*=.*/date\.timezone = \"Asia\/Shanghai\"/' "/etc/php/${phpVer}/fpm/php.ini"

extension_dir=`php -i |grep extension_dir |sed 's/[[:space:]]*=>[[:space:]]*/\n/g' |tail -n1`
wget -qO- "https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_${arch}.tar.gz" | tar -zxv --overwrite -C /tmp
ioncube_path="${extension_dir}/ioncube.so"
cp -rf "/tmp/ioncube/ioncube_loader_lin_${phpVer}.so" "${ioncube_path}"
sed -i '/ioncube\.so/d' "/etc/php/${phpVer}/cli/php.ini"
sed -i '/ioncube\.so/d' "/etc/php/${phpVer}/fpm/php.ini"
echo "zend_extension = ${ioncube_path}" |tee -a "/etc/php/${phpVer}/cli/php.ini" | tee -a "/etc/php/${phpVer}/fpm/php.ini"

php -v
systemctl restart "php${phpVer}-fpm"
systemctl status "php${phpVer}-fpm"
