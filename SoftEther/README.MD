# SoftEther (Linux)

## Require
```
# Debian/Ubuntu
apt-get install -y gcc make

# CentOS
yum install gcc make
```

## Install
```
bash <(wget --no-check-certificate --no-cache -4 -qO- "https://raw.githubusercontent.com/MoeClub/Note/master/SoftEther/SoftEther.sh") -a empty -u vpn -p vpn

```

## Usage
```
bash SoftEther.sh -a [AdminPasswd] -u [User] -p [Passwd]
```

## Network
```
Address: 192.168.233.2 ~ 192.168.233.254
Gateway: 192.168.233.1
NetMask: 255.255.255.0

DNS: 8.8.8.8
```

## Backup Install
```
bash <(wget --no-check-certificate --no-cache -4 -qO- "https://api.moeclub.org/redirect/SoftEther.sh") -a empty -u vpn -p vpn

```

## Local Setting
```
# SoftEther VPN Bridge --> Create Local Bridge
# SoftEther VPN Bridge --> Manage Virtual Hub (BRIDGE) --> Manage Level Connect --> Create

```

## promiscuous mode
```
# linux
ifconfig <ifName> promisc
ifconfig <ifName> -promisc

# windows
netsh wlan show interfaces
Npcap\WlanHelper.exe <GUID OR NAME> mode <MODE>

netsh bridge show adapter
netsh bridge set adapter 1 forcecompatmode=enable


```
