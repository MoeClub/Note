#!/bin/bash

FileBaseName="AriaNgGUI.app.tar.gz"
TMPDIR="$(echo $HOME)/Downloads/AriaNgGUI"
rm -rf "${TMPDIR}"
mkdir -p "${TMPDIR}"
cd "${TMPDIR}"

## Package
#tar -zcvf ./AriaNgGUI.app.tar.gz ./AriaNgGUI.app
#cat ./AriaNgGUI.app.tar.gz |split -b 20m -a 3 - AriaNgGUI.app.tar.gz.

## Download

for num in {1..4}; do
  [ $num -lt 10 ] && FileName="${FileBaseName}.00${num}"
  [ $num -ge 10 ] && [ $num -lt 100 ] && FileName="${FileBaseName}.0${num}"
  [ $num -ge 100 ] && FileName="${FileBaseName}.${num}"
  echo "Download: ${FileName}..."
  curl -sSL -o "${FileName}" "https://raw.githubusercontent.com/MoeClub/Note/master/AriaNgGUI/AriaNgGUI.app/${FileName}"
done

## Install
[ -e "$HOME/Library/Application Support/aria-ng-gui" ] && rm -rf "$HOME/Library/Application Support/aria-ng-gui"
[ -e "/Applications/AriaNgGUI.app" ] && rm -rf "/Applications/AriaNgGUI.app"
tar xvf <(cat AriaNgGUI.app.tar.gz.001 AriaNgGUI.app.tar.gz.002 AriaNgGUI.app.tar.gz.003 AriaNgGUI.app.tar.gz.004) -C "/Applications"
cd ../ && rm -rf "${TMPDIR}"

