# Build Debian 9

```
apt-get update
apt-get install -y gcc make autoconf pkg-config xz-utils
apt-get install -y libgnutls28-dev libev-dev
apt-get install -y libwrap0-dev libpam0g-dev liblz4-dev libseccomp-dev libreadline-dev libnl-route-3-dev libkrb5-dev
apt-get install -y libradcli-dev

version=1.1.0
wget --no-check-certificate -qO ocserv.tar.xz ftp://ftp.infradead.org/pub/ocserv/ocserv-${version}.tar.xz

rm -rf ocserv
mkdir -p ocserv
tar -xvf ocserv.tar.xz -C ocserv --strip-components=1
cd ocserv
autoreconf -fvi

CFLAGS="-fPIC -I." LDFLAGS="-L." \
./configure \
--prefix=/usr \
--disable-rpath \
--without-protobuf \
--without-root-tests \
--without-docker-tests \
--without-nuttcp-tests \
--without-maxmind \
--without-geoip \
--without-liboath \
--without-pam \
--without-radius \
--without-utmp \
--without-lz4 \
--without-http-parser \
--without-gssapi \
--without-pcl-lib \
--with-local-talloc

make && make DESTDIR=/tmp install
```

# Install ocserv v0.12.6
```
wget --no-check-certificate -qO ocserv.tar.gz 'https://github.com/MoeClub/Note/raw/master/AnyConnect/build/ocserv.tar.gz'
tar --overwrite -xvf ocserv.tar -C /

# Config
mkdir -p /etc/ocserv
chmod -R 755 /etc/ocserv

# Debug
/usr/sbin/ocserv -c /etc/ocserv/ocserv.conf -f -d 9 

# Sysctl
sed -i '/^net\.ipv4\.ip_forward/d' /etc/sysctl.conf
while [ -z "$(sed -n '$p' /etc/sysctl.conf)" ]; do sed -i '$d' /etc/sysctl.conf; done
sed -i '$a\net.ipv4.ip_forward = 1\n\n' /etc/sysctl.conf
sysctl -p

# Iptables
bash /etc/ocserv/iptables.rules

```


