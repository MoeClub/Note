# 说明
```
以 15s 的检测间隔, 动态占用至10%的内存使用量.
(如果已使用超过 10% 的内存则不占用内存)
```

# 用法
```
wget -qO- https://github.com/MoeClub/Note/raw/master/Oracle/eat.service >/etc/systemd/system/eat.service

systemctl daemon-reload
systemctl enable eat
systemctl start eat

systemctl status eat       

```
