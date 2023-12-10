# 官方 nrpkg 文件解压

```
备份 bdinfo: dd if /dev/mtd4 of /tmp/bdinfobk.bin
刷入 uboot: mtd -q write /tmp/ubootnew2flash.bin FIP
校验 uboot: mtd -q verify /tmp/ubootnew2flash.bin FIP
刷入 system: mtd -q write /tmp/systemnew2flash.bin ubi
校验 system: mtd -q verify /tmp/systemnew2flash.bin ubi
```

# 刷 ImmortalWRT (OpenWRT) 步骤
```
## 相同的 uboot 只用刷一次, 之后只刷系统镜像即可.
## 使用 mtd 命令刷入时, 一定要看到校验返回 Success 再重启.
## uboot 使用方法: 断电; 连网线插LAN口; 设置地址 192.168.1.100 ; 按住N键后插电, 电源灯有规律闪烁后松开按键; 浏览器进入 192.168.1.1

# 刷入 uboot 步骤 (写入和校验) [8ff84fcbde3f52d65b61c36ccf1f8e5f]
mtd -q write mt7981_nradio_c8-660-u-boot-512m.fip FIP
mtd -q verify mt7981_nradio_c8-660-u-boot-512m.fip FIP

# 刷入系统镜像步骤 (写入和校验)
mtd -q write immortalwrt-mediatek-mt7981-nradio_wt9103_512m-squashfs-factory.bin ubi
mtd -q verify immortalwrt-mediatek-mt7981-nradio_wt9103_512m-squashfs-factory.bin ubi

```

# 换源
```
sed -i 's/mirrors.vsean.net/mirrors.cloud.tencent.com/g;' /etc/opkg/distfeeds.conf
sed -i '/istore/d' /etc/opkg/distfeeds.conf

opkg update
opkg install python3-pip

```

# UCI
```
touch /etc/config/modem
uci add modem network

# Use SIM Card Index
uci set "modem.@network[-1].SIMCard"=1
# Lock PCI, If LockPCI is empty, will lock first PCI.
uci set "modem.@network[-1].StaticPCI"=0
# BAND="", BAND="78", BAND="1:78"
uci set "modem.@network[-1].BandNR5G"=""
# LockPCI="<PCI>,<RFCN>,<BAND>,<SCS>"
uci set "modem.@network[-1].LockPCI"=""
# Network Init Log File
uci set "modem.@network[-1].NetworkLOG"="/tmp/log/network"
# Notice File Name
uci set "modem.@network[-1].NoticeFile"="notice.sh"
# Notice Log File
uci set "modem.@network[-1].NoticeLOG"="/tmp/log/notice"
# Notice PID File
uci set "modem.@network[-1].NoticePID"="/tmp/run/notice.pid"
# Send SMS With Bark
uci set "modem.@network[-1].BarkURL"=""
# Try Max Times
uci set "modem.@network[-1].MaxNum"=120

uci commit modem

```

# 编译
```
cd immortalwrt-mt798x

./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig

make dirclean

FORCE_UNSAFE_CONFIGURE=1 make -j $(nproc)
FORCE_UNSAFE_CONFIGURE=1 make -j $(nproc) V=sc
FORCE_UNSAFE_CONFIGURE=1 make -j 1 V=s

```
