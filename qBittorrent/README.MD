# build
```
bash <(curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/qBittorrent/qbittorrent-nox-static.sh") -i -c -qt release-4.4.2 -lt v2.0.6

cp ~/qbt-build/bin/qbittorrent-nox /tmp/qbittorrent && cd /tmp
XZ_OPT=-9 tar -Jcvf /tmp/qbittorrent_${arch}_qt_v4.4.2_lt_2.0.6.tar.xz qbittorrent

```
