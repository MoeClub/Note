# Build On Debian 9

```
apt-get update
apt-get install -y gcc make autoconf
apt-get install -y libgnutls28-dev libev-dev
apt-get install -y libwrap0-dev libpam0g-dev liblz4-dev libseccomp-dev libreadline-dev libnl-route-3-dev libkrb5-dev
apt-get install -y libradcli-dev

# Download
wget ftp://ftp.infradead.org/pub/ocserv/ocserv-1.1.0.tar.xz

rm -rf ocserv-1.1.0
tar -xvf ocserv-1.1.0.tar.xz
cd ocserv-1.1.0


# Build
./configure --disable-rpath --without-root-tests --without-docker-tests --without-maxmind --without-geoip --without-liboath --without-pam --without-radius --without-utmp --without-libwrap --without-lz4 --without-http-parser  --without-lz4 --without-gssapi --without-pcl-lib

make && make check && make install
```



