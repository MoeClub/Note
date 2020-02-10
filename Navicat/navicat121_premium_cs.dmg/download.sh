#!/bin/bash

FileBaseName="navicat121_premium_cs.dmg.tar.gz"
TMPDIR="$(echo $HOME)/Downloads/Navicat"
rm -rf "${TMPDIR}"
mkdir -p "${TMPDIR}"
cd "${TMPDIR}"

## Download
for num in {1..7}; do
  [ $num -lt 10 ] && FileName="${FileBaseName}.00${num}"
  [ $num -ge 10 ] && [ $num -lt 100 ] && FileName="${FileBaseName}.0${num}"
  [ $num -ge 100 ] && FileName="${FileBaseName}.${num}"
  echo "Download: ${FileName}..."
  curl -sSL -o "${FileName}" "https://raw.githubusercontent.com/MoeClub/Note/master/Navicat/navicat121_premium_cs.dmg/${FileName}"
done

tar -zxvf <(cat navicat121_premium_cs.dmg.tar.gz.001 navicat121_premium_cs.dmg.tar.gz.002 navicat121_premium_cs.dmg.tar.gz.003 navicat121_premium_cs.dmg.tar.gz.004 navicat121_premium_cs.dmg.tar.gz.005 navicat121_premium_cs.dmg.tar.gz.006 navicat121_premium_cs.dmg.tar.gz.007)
cp -rf navicat121_premium_cs.dmg ../
cd ../ && rm -rf "${TMPDIR}"
