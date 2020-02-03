#!/bin/bash

#TMPDIR="$(echo $HOME)/Downloads/UltraEdit_v18.00.0.66"
#rm -rf "${TMPDIR}"
#mkdir -p "${TMPDIR}"
#cd "${TMPDIR}"

# Download
#for num in {1..6}; do
#  FileName="UltraEdit_18.00.0.66.dmg.zip.00${num}"
#  echo "Download: ${FileName}..."
#  curl -sSL -o "${FileName}" "https://raw.githubusercontent.com/MoeClub/Note/master/UltraEdit/UltraEdit_18.00.0.66.dmg/${FileName}"
#done
#tar xvf <(cat UltraEdit_18.00.0.66.dmg.zip.001 UltraEdit_18.00.0.66.dmg.zip.002 UltraEdit_18.00.0.66.dmg.zip.003 UltraEdit_18.00.0.66.dmg.zip.004 UltraEdit_18.00.0.66.dmg.zip.005 UltraEdit_18.00.0.66.dmg.zip.006)
#cp -rf UltraEdit_18.00.0.66.dmg ../
#cd ../ && rm -rf "${TMPDIR}"

# Install
hdiutil attach "UltraEdit_18.00.0.66.dmg" -nobrowse
cp -rf "/Volumes/UltraEdit 18.00.0.66/UltraEdit.app" /Applications
hdiutil detach "/Volumes/UltraEdit 18.00.0.66"

# Done
printf '\x31\xC0\xFF\xC0\xC3\x90' | dd seek=$((0x74B480)) conv=notrunc bs=1 of=/Applications/UltraEdit.app/Contents/MacOS/UltraEdit
printf '\x31\xC0\xFF\xC0\xC3\x90' | dd seek=$((0x760900)) conv=notrunc bs=1 of=/Applications/UltraEdit.app/Contents/MacOS/UltraEdit

