#!/bin/bash

ARCH=("aarch64-linux-musl" "x86_64-linux-musl" "x86_64-w64-mingw32");

ROOTDIR="/usr/local/musl"
mkdir -p "${ROOTDIR}"

for arch in ${ARCH[@]} ; do
  wget -qO- "http://musl.cc/${arch}-cross.tgz" |tar -zx --overwrite -C "${ROOTDIR}";
done

PATH_VAR=""
for path in `echo "$PATH" |sed 's/:/\n/g'`; do echo "$path" |grep -q "musl" || PATH_VAR+=":${path}"; done
for path in `find "${ROOTDIR}" -name "*-cc" 2>/dev/null`; do PATH_VAR+=":$(dirname ${path})"; done

PATH_VAR=`echo "$PATH_VAR" |sed 's/^://g'`
sed -i '/^PATH=/d' $HOME/.bashrc
echo "PATH=${PATH_VAR}" >>$HOME/.bashrc

