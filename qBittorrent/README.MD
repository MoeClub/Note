# build
```
bash ~/qbittorrent-nox-static.sh all -i -c -qt release-4.4.2 -lt v2.0.6

cp build/qbittorrent /tmp/qbittorrent && cd /tmp
XZ_OPT=-9 tar -Jcvf /tmp/qbittorrent_${arch}_qt_v4.4.2_lt_2.0.6.tar.xz qbittorrent

```
