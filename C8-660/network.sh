#!/bin/sh

PORT=2
MaxNum=120
LOG="/tmp/network.log"

[ -f /bin/sendat ] && [ -f /sbin/ifup ] || exit 1

function WaitAT() {
  for i in $(seq 1 $MaxNum); do
    if [ -e "/dev/ttyUSB${PORT}" ]; then
      /bin/sendat "$PORT" 'AT' |grep 'OK'
      [ $? -eq 0 ] && return 0
    fi
    sleep 1 
  done
  return 1
}

function Now() {
  echo -ne `date '+[%Y/%m/%d %H:%M:%S']`
}

echo "$(Now) START" |tee -a "$LOG"

WaitAT || exit 1

echo "$(Now) Init ..." |tee -a "$LOG"
/bin/sendat "$PORT" 'AT&F0'

echo "$(Now) Wait SIM ..." |tee -a "$LOG"
for i in $(seq 1 $MaxNum); do
  stat=`/bin/sendat "$PORT" 'AT+QINISTAT' |grep '+QINISTAT:' |grep -o '[0-9]*'`
  echo "$(Now) SIM Satus: $stat" |tee -a "$LOG"
  [ "$stat" -ne 7 ] && sleep 1 && continue || break 
 done
 
WaitAT || exit 1

echo "$(Now) Set PCIE ..." |tee -a "$LOG"
/bin/sendat "$PORT" 'AT+QCFG="pcie_mbim",0'
/bin/sendat "$PORT" 'AT+QCFG="pcie/mode",1'
/bin/sendat "$PORT" 'AT+QCFG="data_interface",1,0'

/bin/sendat "$PORT" 'AT+QETH="eth_driver","r8168",0'
/bin/sendat "$PORT" 'AT+QETH="eth_driver","r8125",1'

echo "$(Now) Set NR5G ..." |tee -a "$LOG"
/bin/sendat "$PORT" 'AT+QMAPWAC=1'
/bin/sendat "$PORT" 'AT+QUIMSLOT=1'
/bin/sendat "$PORT" 'AT+QSCLK=0,0'
/bin/sendat "$PORT" 'AT+CFUN=1,1'
/bin/sendat "$PORT" 'AT+QNWCFG="data_roaming",1'
/bin/sendat "$PORT" 'AT+QNWPREFCFG="roam_pref",255'
/bin/sendat "$PORT" 'AT+QNWPREFCFG="mode_pref",NR5G'
/bin/sendat "$PORT" 'AT+QNWPREFCFG="nr5g_disable_mode",2'
/bin/sendat "$PORT" 'AT+QNWPREFCFG="nr5g_band",78'

WaitAT || exit 1

function MPDN() {
  WaitAT || return 1
  
  echo "$(Now) Reset MPDN ..." |tee -a "$LOG"
  /bin/sendat "$PORT" 'AT+QMAP="mPDN_rule",0' |grep 'OK\|ERROR'
  [ $? -ne 0 ] && sleep 5 && return 1
  
  for i in $(seq 1 $MaxNum); do
    result=`/bin/sendat "$PORT" 'AT+QMAP="mPDN_rule"'`
    echo "$result" |grep -q '0,0,0,0,0'
    [ $? -eq 0 ] && break || sleep 1
    echo "$result" |grep -q '0,1,0,1,1'
    [ $? -eq 0 ] && return 1
  done

  echo "$(Now) Set MPDN ..." |tee -a "$LOG"
  /bin/sendat "$PORT" 'AT+QMAP="mPDN_rule",0,1,0,1,1,"FF:FF:FF:FF:FF:FF"' |grep 'OK\|ERROR'
  [ $? -ne 0 ] && sleep 5 && return 1
  
  for i in $(seq 1 $MaxNum); do
    result=`/bin/sendat "$PORT" 'AT+QMAP="mPDN_rule"'`
    echo "$result" |grep -q '0,1,0,1,1'
    [ $? -eq 0 ] && break || sleep 1
    echo "$result" |grep -q '0,0,0,0,0'
    [ $? -eq 0 ] && return 1
  done
  
  echo "$(Now) Reload Interface ..." |tee -a "$LOG"
  /sbin/ifup wan
  /sbin/ifup wan6

  return 0
}

function CheckIPv4() {
  echo "$(Now) Check IPv4 ..." |tee -a "$LOG"
  for i in $(seq 1 $MaxNum); do
    ipv4=`ubus call network.interface.wan status 2>/dev/null |grep '"address":' |grep -o '[0-9\.]*'`
    [ -n "$ipv4" ] && echo "$(Now) IPv4: $ipv4" |tee -a "$LOG" && return 0
    sleep 1
  done
  return 1
}

# /bin/sendat 3 'AT+QSCAN=2,1'
# /bin/sendat 3 'AT'
# /bin/sendat 3 'AT+QNWCFG="nr5g_earfcn_lock"'

while true; do
  MPDN || continue
  CheckIPv4 && break
done

echo "$(Now) FINISH" |tee -a "$LOG"

