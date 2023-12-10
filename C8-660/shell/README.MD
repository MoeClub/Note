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
