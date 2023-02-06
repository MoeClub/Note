# Usage
```
wget -qO- https://github.com/MoeClub/Note/raw/master/Oracle/eat.service >/etc/systemd/system/eat.service

systemctl daemon-reload
systemctl enable eat
systemctl start eat

systemctl status eat       

```
