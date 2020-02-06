#!/bin/bash

[ "$(sudo whoami)" == "root" ] || exit 1
[ -e "/usr/local/bin" ] || mkdir -p "/usr/local/bin"
[ -e "/usr/local/Cellar" ] || mkdir -p "/usr/local/Cellar"
chmod 777 "/usr/local/Cellar"
tar -xvf <(curl -fsSL "https://raw.githubusercontent.com/MoeClub/Note/master/hping/hping.tar") -C "/usr/local/Cellar"
sudo ln -sf "/usr/local/Cellar/hping/hping3" "/usr/local/bin/hping"
sudo chown root:wheel "/usr/local/Cellar/hping/hping3"
sudo chmod ug+s "/usr/local/Cellar/hping/hping3"

