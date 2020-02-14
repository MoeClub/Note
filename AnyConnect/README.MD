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
# 本机地址未知,性能较低.
# iptables -t nat -I POSTROUTING -d <远程地址> -p tcp --dport <远程端口> -j MASQUERADE
# 绑定网卡
# iptables -t nat -A PREROUTING -p tcp -i <网卡名称> --dport <本机端口> -j DNAT --to-destination <远程地址>:<远程端口> 
# iptables -t nat -I POSTROUTING -o <网卡名称> -j MASQUERADE
```
