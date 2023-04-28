# MacOS
```
curl -sSL "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/mac.sh" |bash -s <CERT_URL> <CERT_PWD>

```

# iOS
```
anyconnect://create?usecert=true&certcommonname=<CERT_NAME>&name=<NAME>&host=<SERVER>
anyconnect://import?type=profile&uri=<PROFILE_URL>
anyconnect://import?type=pkcs12&uri=<CERT_URL>

anyconnect://connect/?name=<NAME>&onsuccess=anyconnect%3A%2F%2Fclose&onerror=anyconnect%3A%2F%2Fclose
anyconnect://disconnect/?onsuccess=anyconnect%3A%2F%2Fclose&onerror=anyconnect%3A%2F%2Fclose
```

# Preferences
```
# profile.xml
## windows: %ProgramData%\Cisco\Cisco AnyConnect Secure Mobility Client\Profile\profile.xml
## mac/linux: /opt/cisco/anyconnect/profile/profile.xml

# preferences_global.xml
## windows: %ProgramData%\Cisco\Cisco AnyConnect Secure Mobility Client\preferences_global.xml
## mac/linux: /opt/cisco/anyconnect/.anyconnect_global

# preferences.xml
## windows: %LocalAppData%\Cisco\Cisco AnyConnect Secure Mobility Client\preferences.xml
## mac/linux: $Home/.anyconnect

```

# 端口转发
```
iptables -t nat -A PREROUTING -d <本机地址> -p tcp --dport <本机端口> -j DNAT --to-destination <远程地址>:<远程端口> 
iptables -t nat -I POSTROUTING -d <远程地址> -p tcp --dport <远程端口> -j MASQUERADE
```

# ocserv.deb [ Debian 10+ / Ubuntu 18+ ] (AMD64/ARM64)
```
wget --no-check-certificate --no-cache -4 -qO /tmp/ocserv.deb "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv.deb" && dpkg -i /tmp/ocserv.deb

```

# docker
```
docker build -t ocserv:latest ./DockerFile; 

docker run --name ocserv --env PASSWD=-Test:TestPwd:NoRoute --env CERT=<CERT_URL> --env KEY=<KEY_URL> --env CA=<CA_URL> --privileged -p 443:443 -d <ImageID> 

docker rm -f ocserv


--env CA=      # 用于证书登陆
--env PASSWD=  # 用于用户名密码登陆
--env CERT=    # 用于域名证书
--env KEY= 

```

# 证书认证
```
bash /etc/ocserv/template/client.sh -o <OrgName> -g <GroupName> -p <PASSWORD> -i <CN>
## -o, 证书上显示的组织名.
## -p, 证书密码可为空, 在iOS上只能导入已设置密码的证书
## -g, 设置分组, 一般用于区分路由表. [Default, NoRoute]
## -i, 初始化CA证书. [留空, 服务器IP, 域名]

# 重新初始化 CA
bash /etc/ocserv/template/client.sh -o <OrgName> -i <CN>

# 设置用户证书
bash /etc/ocserv/template/client.sh -o <OrgName> -g <GroupName> -p <PASSWORD>
## 示例: bash /etc/ocserv/template/client.sh -o "MoeClub" -g "NoRoute" -p "P@Ssw0rd"

```

# ocserv.sh Debian x64 8+ / CentOS 6+ / Ubuntu 14+)
```
bash <(wget --no-check-certificate --no-cache -4 -qO- "https://raw.githubusercontent.com/MoeClub/Note/master/AnyConnect/ocserv.sh")
```
## 安装后需要的一些工作([域名证书可点此查看申请步骤](https://github.com/MoeClub/AlphaSSL))
- 将域名证书上传至 `/etc/ocserv/server.cert.pem`
- 将域名证书私钥上传至 `/etc/ocserv/server.key.pem`
- 如果有多组服务器, 备份保存CA证书 `/etc/ocserv/template/ca.cert.pem` 和 `/etc/ocserv/template/ca.key.pem`.      
  (替换 `ca.cert.pem` 文件即可使用)
- **预设用户名**为`Default`,`NoRoute`; **预设密码**为`MoeClub`.(可自行更改`/etc/ocserv/ocpasswd`)      
  - 用户密码格式: `<用户名>:<用户组>:<用户密码密文>`       
  - 用户密码密文: `openssl passwd MoeClub` (`MoeClub`为密码)     
- 注意事项(**因系统限制**)
  - iOS, MacOS, Windows 用户请使用 `NoRoute` 分组, 预设用户名为 `NoRoute`.
  - Android 用户请使用 `Default` 分组, 预设用户名为 `Default`.
```
## 非必要步骤
# 修改 SSH 端口 (改为 9527)
sed -i "s/^#\?Port .*/Port 9527/g" /etc/ssh/sshd_config;
# 修改 ocserv 端口(TCP 改为 23443)
sed -i "s/^#\?tcp-port.*/tcp-port=23443/g" /etc/ocserv/ocserv.conf;
# 生成用户证书(根据CA证书验证,如果部署多个.请保证CA证书相同)
bash /etc/ocserv/template/client.sh -g <分组名字> -p <证书密码,苹果设备不能为空>
```

# 使用 BBR 加速纯 TCP 模式的流量
```
bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/apt/master/bbr/bbr.sh')

```
