#!bin/bash
# Install Deluge


delugePwd="${1:-deluge}"
apt-get update --allow-releaseinfo-change
apt-get install -y python python-twisted python-openssl python-setuptools intltool python-xdg python-chardet python-libtorrent python-notify python-pygame python-glade2 librsvg2-common xdg-utils python-mako 

RSC="https://raw.githubusercontent.com/MoeClub/Note/master/Deluge/deluge"
wget --no-check-certificate -qO- "${RSC}/deluge-1.3.15.tar.gz" |tar -zvx -C /tmp
cd /tmp/deluge-* && ppython setup.py install --force --install-layout=deb --single-version-externally-managed --record /tmp/deluge.log

pip3 install lxml==4.3.5 deluge_client

mkdir -p "$HOME/.config/deluge/plugins"
wget --no-check-certificate -qO "$HOME/.config/deluge/deluged" "${RSC}/deluged"
wget --no-check-certificate -qO "$HOME/.config/deluge/deluge_passwd.py" "${RSC}deluge_passwd.py"
wget --no-check-certificate -qO "$HOME/.config/deluge/web.conf" "${RSC}/web.conf"
wget --no-check-certificate -qO "$HOME/.config/deluge/core.conf" "${RSC}/core.conf"
wget --no-check-certificate -qO "$HOME/.config/deluge/ltconfig.conf" "${RSC}/ltconfig.conf"
wget --no-check-certificate -qO "$HOME/.config/deluge/plugins/ltConfig-0.3.1-py2.7.egg" "${RSC}/plugins/ltConfig-0.3.1-py2.7.egg"

if [ -f "$HOME/.config/deluge/core.conf" ]; then
  grep '"download_location":' "$HOME/.config/deluge/core.conf" |cut -d'"' -f4 |xargs mkdir -p
fi

bash "$HOME/.config/deluge/deluged" init
python "$HOME/.config/deluge/deluge_passwd.py" "$delugePwd"

IPAddress="$(wget --no-check-certificate -qO- 'http://checkip.amazonaws.com' |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}')"
echo -ne "\nWebUI URL: http://${IPAddress}:8112/deluge/\nPassword: $delugePwd\nUsage: deluge-ctl [start|stop]\n"
