# nrpkg 文件解包后有3个文件

```
一个系统镜像(重命名为systemnew2flash.bin)，
一个uboot(重命名为ubootnew2flash.bin)，
一个描述文件。

备份 bdinfo:  dd if /dev/mtd4 of /tmp/bdinfobk.bin

刷入 uboot: mtd -q write /tmp/ubootnew2flash.bin FIP
校验 uboot: mtd -q verify /tmp/ubootnew2flash.bin FIP
刷入 system: mtd -q write /tmp/systemnew2flash.bin ubi
校验 system: mtd -q verify /tmp/systemnew2flash.bin ubi
```

# 换源
```
sed -i 's/mirrors.vsean.net/mirrors.cloud.tencent.com/g;' /etc/opkg/distfeeds.conf
sed -i '/istore/d' /etc/opkg/distfeeds.conf

opkg update
opkg install jq

```

# UCI
```
touch /etc/config/modem
uci add modem network
uci set modem.@network[-1].SIMCardIndex=1
uci set modem.@network[-1].StaticPCI=1
uci set modem.@network[-1].ResetNVRAM=0
uci set modem.@network[-1].NR5GBand=""
uci set modem.@network[-1].LockPCI=""
uci set modem.@network[-1].BarkURL=""
uci commit modem

```

# 编译
```
cd immortalwrt-mt798x
./scripts/feeds update -a
./scripts/feeds install -a

FORCE_UNSAFE_CONFIGURE=1 make -j4
```
