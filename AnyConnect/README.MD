# MacOS
```
bash <(curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/mac.sh") <CERT_URL> <CERT_PWD>
```

# iOS
```
anyconnect://create?usecert=true&certcommonname=<CERT_NAME>&name=<NAME>&host=<SERVER>
anyconnect://import?type=profile&uri=<PROFILE_URL>
anyconnect://import?type=pkcs12&uri=<CERT_URL>

anyconnect://connect/?name=<NAME>&onsuccess=anyconnect%3A%2F%2Fclose&onerror=anyconnect%3A%2F%2Fclose
anyconnect://disconnect/?onsuccess=anyconnect%3A%2F%2Fclose&onerror=anyconnect%3A%2F%2Fclose
```

# 端口转发
```
iptables -t nat -A PREROUTING -d <本机地址> -p tcp --dport <本机端口> -j DNAT --to-destination <远程地址>:<远程端口> 
iptables -t nat -A POSTROUTING -d <远程地址> -p tcp --dport <远程端口> -j SNAT --to-source <本机地址>

# 其他实现方式.
# iptables -t nat -I POSTROUTING -d <远程地址> -p tcp --dport <远程端口> -j MASQUERADE

# 绑定网卡
# iptables -t nat -A PREROUTING -p tcp -i <网卡名称> --dport <本机端口> -j DNAT --to-destination <远程地址>:<远程端口> 
# iptables -t nat -I POSTROUTING -o <网卡名称> -j MASQUERADE
```

# ocserv.sh
```
bash <(curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv.sh")
```
```
# 修改 SSH 端口 (改为 9527)
sed -i "s/^#\?Port .*/Port 9527/g" /etc/ssh/sshd_config;
# 修改 ocserv 端口(TCP 改为 23443)
sed -i "s/^#\?tcp-port .*/tcp-port 23443/g" /etc/ocserv/ocserv.conf;
# 生成用户证书(根据CA证书验证,如果部署多个.请保证CA证书相同)
bash /etc/ocserv/template/client.sh <证书密码,苹果设备不能为空>
```
