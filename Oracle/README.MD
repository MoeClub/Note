# 说明
```
以 15s 的检测间隔, 动态占用至15%的内存使用量.
(如果已使用超过 15% 的内存则不占用内存)

删除 /run/shm/MemoryEat.bin 则自动停止占用内存, 直到下次重启服务.

```

# 用法
```
wget -qO- https://github.com/MoeClub/Note/raw/master/Oracle/eat.service >/etc/systemd/system/eat.service

systemctl daemon-reload
systemctl enable eat
systemctl start eat

systemctl status eat       

```

# 卸载
```
systemctl disable eat
rm -rf /etc/systemd/system/eat.service
rm -rf /run/shm/MemoryEat.bin

```

