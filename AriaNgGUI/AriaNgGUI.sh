#!/bin/bash

TMPDIR="$(echo $HOME)/Downloads/AriaNgGUI"
rm -rf "${TMPDIR}"
mkdir -p "${TMPDIR}"
cd "${TMPDIR}"

# Download
for num in {1..10}; do
  [ $num -lt 10 ] && FileName="AriaNgGUI.app.zip.00${num}"
  [ $num -ge 10 ] && [ $num -lt 100 ] && FileName="AriaNgGUI.app.zip.0${num}"
  [ $num -ge 100 ] && FileName="AriaNgGUI.app.zip.${num}"
  echo "Download: ${FileName}..."
  curl -sSL -o "${FileName}" "https://raw.githubusercontent.com/MoeClub/Note/master/AriaNgGUI/AriaNgGUI/${FileName}"
done

# Install
tar xvf <(cat AriaNgGUI.app.zip.001 AriaNgGUI.app.zip.002 AriaNgGUI.app.zip.003 AriaNgGUI.app.zip.004 AriaNgGUI.app.zip.005 AriaNgGUI.app.zip.006 AriaNgGUI.app.zip.007 AriaNgGUI.app.zip.008 AriaNgGUI.app.zip.009 AriaNgGUI.app.zip.010) -C "/Applications"
cd ../ && rm -rf "${TMPDIR}"

