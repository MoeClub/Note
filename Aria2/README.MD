# download
```
# AMD64
wget -qO- "https://raw.githubusercontent.com/MoeClub/Note/master/Aria2/aria2c_amd64_v1.36.0.tar.gz" |tar -zxv

# ARM64
wget -qO- "https://raw.githubusercontent.com/MoeClub/Note/master/Aria2/aria2c_arm64_v1.36.0.tar.gz" |tar -zxv

```

# static build
```
bash <(wget -qO- https://raw.githubusercontent.com/MoeClub/Note/master/Aria2/aria2.sh)

cd /tmp && tar -zcvf aria2c_$(uname -m)_v1.36.0.tar.gz aria2c

```

# install
```
bash <(wget -qO- https://github.com/MoeClub/Note/raw/master/Aria2/install.sh)

```
