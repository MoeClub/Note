#!/bin/bash

cores=`grep "^processor" /proc/cpuinfo |wc -l`
[ -n "$cores" ] || cores=1

C_COMPILER="gcc"
CXX_COMPILER="g++"
BUILD_DIRECTORY="/tmp"
PREFIX="$BUILD_DIRECTORY/aria2_build"

DOWNLOADER() {
  [ "$#" -eq 2 ] || return
  rm -rf "./$2"
  mkdir -p "./$2"
  wget -qO- "$1" |tar -zxv --strip-components 1 -C "./$2"
}

MOD() {
 [ "$#" -eq 5 ] || return
 n=`grep -on "$2" "$1" |cut -d':' -f1`
 sed -i "$(($n+$3))s/$4/$5/" "$1"
}

## DEPENDENCES ##
OPENSSL="https://www.openssl.org/source/openssl-1.1.1o.tar.gz"
ZLIB="http://sourceforge.net/projects/libpng/files/zlib/1.2.11/zlib-1.2.11.tar.gz"
EXPAT="https://github.com/libexpat/libexpat/releases/download/R_2_4_8/expat-2.4.8.tar.gz"
SQLITE3="https://sqlite.org/2021/sqlite-autoconf-3360000.tar.gz"
C_ARES="https://c-ares.haxx.se/download/c-ares-1.17.2.tar.gz"
SSH2="https://www.libssh2.org/download/libssh2-1.9.0.tar.gz"
ARIA2="https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0.tar.gz"

mkdir -p "$PREFIX"

# zlib
cd "$BUILD_DIRECTORY"
DOWNLOADER "$ZLIB" "zlib"
cd ./zlib
PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/ LD_LIBRARY_PATH=$PREFIX/lib/ CC="$C_COMPILER" CXX="$CXX_COMPILER" ./configure --prefix=$PREFIX --static
make -j $cores && make install || exit 1
rm -rf ../zlib

# expat
cd "$BUILD_DIRECTORY"
DOWNLOADER "$EXPAT" "expat"
cd ./expat
PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/ LD_LIBRARY_PATH=$PREFIX/lib/ CC="$C_COMPILER" CXX="$CXX_COMPILER" ./configure --prefix=$PREFIX --enable-static --disable-shared
make -j $cores && make install || exit 1
rm -rf ../expat

# c-ares
cd "$BUILD_DIRECTORY"
DOWNLOADER "$C_ARES" "c-ares"
cd ./c-ares
PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/ LD_LIBRARY_PATH=$PREFIX/lib/ CC="$C_COMPILER" CXX="$CXX_COMPILER" ./configure --prefix=$PREFIX --enable-static --disable-shared
make -j $cores && make install || exit 1
rm -rf ../c-ares

# sqlite3
cd "$BUILD_DIRECTORY"
DOWNLOADER "$SQLITE3" "sqlite3"
cd ./sqlite3
PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/ LD_LIBRARY_PATH=$PREFIX/lib/ CC="$C_COMPILER" CXX="$CXX_COMPILER" ./configure --prefix=$PREFIX --enable-static --disable-shared
make -j $cores && make install || exit 1
rm -rf ../sqlite3

# openssl build
cd "$BUILD_DIRECTORY"
DOWNLOADER "$OPENSSL" "openssl"
cd ./openssl
PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/ LD_LIBRARY_PATH=$PREFIX/lib/ CC="$C_COMPILER" CXX="$CXX_COMPILER" ./config --prefix=$PREFIX
make -j $cores && make install || exit 1
rm -rf ../openssl

# libssh2
cd "$BUILD_DIRECTORY"
DOWNLOADER "$SSH2" "libssh2"
cd ./libssh2
rm -rf "$PREFIX/lib/pkgconfig/libssh2.pc"
PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/ LD_LIBRARY_PATH=$PREFIX/lib/ CC="$C_COMPILER" CXX="$CXX_COMPILER" ./configure --without-libgcrypt --with-openssl --without-wincng --prefix=$PREFIX --enable-static --disable-shared
make -j $cores && make install || exit 1
rm -rf ../libssh2

# aria2
cd "$BUILD_DIRECTORY"
DOWNLOADER "$ARIA2" "aria2"
cd ./aria2

# aria2 v1.36.0 mod --> file, tag, offset, src, target
MOD "src/OptionHandlerFactory.cc" "PREF_SPLIT" "0" '"5",' '"65535",'
MOD "src/OptionHandlerFactory.cc" "PREF_MIN_SPLIT_SIZE" "0" '"20M",' '"8M",'
MOD "src/OptionHandlerFactory.cc" "PREF_MAX_CONCURRENT_DOWNLOADS" "2" '"5",' '"16",'
MOD "src/OptionHandlerFactory.cc" "PREF_MAX_CONNECTION_PER_SERVER" "2" '"1", 1, 16,' '"16", 1, 1024,'
# MOD "src/OptionHandlerFactory.cc" "PREF_CONTINUE" "0" 'A2_V_FALSE' 'A2_V_TRUE'
MOD "src/OptionHandlerFactory.cc" "PREF_DISABLE_IPV6" "11" 'A2_V_FALSE' 'A2_V_TRUE'
MOD "src/OptionHandlerFactory.cc" "PREF_SUMMARY_INTERVAL" "0" '"60",' '"0",'

# aria2 build
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig/" \
LD_LIBRARY_PATH="$PREFIX/lib/" \
CC="$C_COMPILER" \
CXX="$CXX_COMPILER" \
./configure \
    --prefix=$PREFIX \
    --without-libxml2 \
    --without-libgcrypt \
    --without-libnettle \
    --without-gnutls \
    --without-libgmp \
    --with-openssl \
    --with-libssh2 \
    --with-sqlite3 \
    --with-ca-bundle="/etc/ssl/certs/ca-certificates.crt" \
    --enable-shared=no \
    ARIA2_STATIC=yes
make -j $cores && make install || exit 1
rm -rf ../aria2

# aria2c
rm -rf "$BUILD_DIRECTORY/aria2c"
cp "$PREFIX/bin/aria2c" "$BUILD_DIRECTORY/"
$BUILD_DIRECTORY/aria2c -v && strip -s $BUILD_DIRECTORY/aria2c && ldd $BUILD_DIRECTORY/aria2c

