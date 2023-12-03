#!/bin/sh

PORT=2
MaxNum=120
LOG="/tmp/network.log"
BAND="78"
# BAND="", BAND="78", BAND="1:78"


[ -e /bin/sendat ] || exit 1

function Now() {
  echo -ne `date '+[%Y/%m/%d %H:%M:%S']`
}

function WaitAT() {
  for i in $(seq 1 $MaxNum); do
    if [ -e "/dev/ttyUSB${PORT}" ]; then
      /bin/sendat "$PORT" 'AT' |grep -q 'OK'
      [ $? -eq 0 ] && return 0
    fi
    sleep 1 
  done
  return 1
}

function WaitSIM(){
  WaitAT || return 1
  echo "$(Now) Wait SIM ..." |tee -a "$LOG"
  for i in $(seq 1 $MaxNum); do
    stat=`/bin/sendat "$PORT" 'AT+QINISTAT' |grep '+QINISTAT:' |grep -o '[0-9]*'`
    echo "$(Now) SIM Satus: $stat" |tee -a "$LOG"
    [ "$stat" -ne 7 ] && sleep 1 && continue || break 
   done
}

function Driver(){
  echo "$(Now) Set Driver ..." |tee -a "$LOG"
  /bin/sendat "$PORT" 'AT&F0'
  /bin/sendat "$PORT" 'AT+QCFG="pcie_mbim",0'
  /bin/sendat "$PORT" 'AT+QCFG="pcie/mode",1'
  /bin/sendat "$PORT" 'AT+QCFG="data_interface",1,0'
  /bin/sendat "$PORT" 'AT+QETH="eth_driver","r8168",0'
  /bin/sendat "$PORT" 'AT+QETH="eth_driver","r8125",1'
}

function NR5G(){
  rfBand=`/bin/sendat "$PORT" 'AT+QNWPREFCFG="rf_band"' |grep '+QNWPREFCFG:\s*"nr5g_band"' |cut -d',' -f2 |grep -o '[0-9A-Za-z:]*'`
  band=${1:-$rfBand}
  echo "$(Now) Set NR5G ${band} ..." |tee -a "$LOG"
  /bin/sendat "$PORT" 'AT+QNWCFG="data_roaming",1'
  /bin/sendat "$PORT" 'AT+QNWPREFCFG="roam_pref",255'
  /bin/sendat "$PORT" 'AT+QNWPREFCFG="mode_pref",NR5G'
  /bin/sendat "$PORT" 'AT+QNWPREFCFG="nr5g_disable_mode",2'
  /bin/sendat "$PORT" "AT+QNWPREFCFG=\"nr5g_band\",${band}"
}

function Reset(){
  echo "$(Now) Reset Modem ..." |tee -a "$LOG"
  /bin/sendat "$PORT" 'AT+QSCLK=0,0'
  /bin/sendat "$PORT" 'AT+QMAPWAC=1'
  /bin/sendat "$PORT" 'AT+QUIMSLOT=1'
  [ $1 -gt 0 ] && /bin/sendat "$PORT" 'AT+CFUN=1,1'
  sleep 5
}

function MPDN() {
  WaitAT || return 1
  
  echo "$(Now) Empty MPDN ..." |tee -a "$LOG"
  /bin/sendat "$PORT" 'AT+QMAP="mPDN_rule",0'
  sleep 5

  WaitAT || return 1
  for i in $(seq 1 $MaxNum); do
    result=`/bin/sendat "$PORT" 'AT+QMAP="mPDN_rule"'`
    echo "$result" |grep -q '0,0,0,0,0'
    [ $? -eq 0 ] && break || sleep 1
    echo "$result" |grep -q '0,1,0,1,1'
    [ $? -eq 0 ] && return 1
  done

  WaitAT || return 1
  echo "$(Now) Reset MPDN ..." |tee -a "$LOG"
  /bin/sendat "$PORT" 'AT+QMAP="mPDN_rule",0,1,0,1,1,"FF:FF:FF:FF:FF:FF"'
  sleep 5

  WaitAT || return 1
  for i in $(seq 1 $MaxNum); do
    result=`/bin/sendat "$PORT" 'AT+QMAP="mPDN_rule"'`
    echo "$result" |grep -q '0,1,0,1,1'
    [ $? -eq 0 ] && break || sleep 1
    echo "$result" |grep -q '0,0,0,0,0'
    [ $? -eq 0 ] && return 1
  done
}

function CheckIPv4() {
  WaitAT || return 1
  echo "$(Now) Check IPv4 ..." |tee -a "$LOG"
  maxNum=$(($MaxNum/4))
  for i in $(seq 1 $maxNum); do
    ipv4=`/bin/sendat "$PORT" 'AT+CGPADDR=1' |grep '+CGPADDR:' |cut -d',' -f2 |grep -o '[0-9\.]*'`
    [ -n "$ipv4" ] && [ "$ipv4" != "0.0.0.0" ] && echo "$(Now) IPv4: $ipv4" |tee -a "$LOG" && return 0
    sleep 1
  done
  return 1
}

function ReloadIf() {
  [ -e /sbin/ifup ] || return 1
  echo "$(Now) Reload Interface ..." |tee -a "$LOG"
  /sbin/ifup wan
  /sbin/ifup wan6
  return 0
}

# /bin/sendat 3 'AT+QSCAN=2,1'
# /bin/sendat 3 'AT'
# /bin/sendat 3 'AT+QNWCFG="nr5g_earfcn_lock"'

echo "$(Now) START" |tee -a "$LOG"

for i in $(seq 1 $MaxNum); do
  n=$(($i/2))
  m=$(($i%2))
  
  [ $m -eq 1 ] && {
    [ $n -eq 0 ] && {
      Driver
      NR5G "$BAND"
    }
    Reset "$n"
    WaitSIM
  }
  
  MPDN || continue
  CheckIPv4 && ReloadIf && break
done

echo "$(Now) FINISH" |tee -a "$LOG"

