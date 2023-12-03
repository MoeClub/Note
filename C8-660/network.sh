#!/bin/sh

# Lock PCI, If PCILock is empty, will lock first PCI.
PCIStatic=1
# PCILock="<PCI>,<RFCN>,<BAND>,<SCS>"
PCILock="530,627264,78,1"
# BAND="", BAND="78", BAND="1:78"
BAND=""
# Use SIM Card Index
SIMCardIndex=1
# Empty NVRAM
EmptyNVRAM=0


[ -e /bin/sendat ] || exit 1

PORT=2
MaxNum=120
LOG="/tmp/network.log"

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
  [ $1 -gt 0 ] && /bin/sendat "$PORT" 'AT+QPRTPARA=3'
  /bin/sendat "$PORT" 'AT+QCFG="pcie/mode",1'
  /bin/sendat "$PORT" 'AT+QCFG="data_interface",1,0'
  /bin/sendat "$PORT" 'AT+QETH="eth_driver","r8168",0'
  /bin/sendat "$PORT" 'AT+QETH="eth_driver","r8125",1'
  /bin/sendat "$PORT" 'AT+QCFG="volte_disable",0'
  /bin/sendat "$PORT" 'AT+QCFG="sms_control",1,1'
  /bin/sendat "$PORT" 'AT+QCFG="call_control",0,0'
  /bin/sendat "$PORT" 'AT+CPMS="ME","ME","ME"'
  /bin/sendat "$PORT" 'AT+CMGF=0'
}

function NR5G(){
  rfBand=`/bin/sendat "$PORT" 'AT+QNWPREFCFG="rf_band"' |grep '+QNWPREFCFG:\s*"nr5g_band"' |cut -d',' -f2 |grep -o '[0-9A-Za-z:]*'`
  band="${1:-$rfBand}"
  echo "$(Now) Set NR5G ${band} ..." |tee -a "$LOG"
  /bin/sendat "$PORT" 'AT+QNWPREFCFG="roam_pref",255'
  /bin/sendat "$PORT" 'AT+QNWPREFCFG="rat_acq_order",NR5G:LTE:WCDMA'
  /bin/sendat "$PORT" 'AT+QNWPREFCFG="mode_pref",NR5G'
  /bin/sendat "$PORT" 'AT+QNWPREFCFG="nr5g_disable_mode",2'
  /bin/sendat "$PORT" "AT+QNWPREFCFG=\"nr5g_band\",${band}"
}

function COPS(){
  echo "$(Now) Search COPS ..." |tee -a "$LOG"
  /bin/sendat "$PORT" 'AT+COPS=2'
  /bin/sendat "$PORT" 'AT+COPS=0'
  for i in $(seq 1 $MaxNum); do
    cops=`/bin/sendat "$PORT" 'AT+COPS?' |grep '+COPS: 0,'  |cut -d'"' -f2 |sed 's/[[:space:]]//g'`
    [ -n "$cops" ] && echo "$(Now) COPS: $cops" |tee -a "$LOG" && break || sleep 1
  done
}

function Modem(){
  echo "$(Now) Reset Modem ..." |tee -a "$LOG"
  SIMCard="${1:-1}"
  ResetModem="${2:-0}"
  /bin/sendat "$PORT" 'AT+QNWCFG="data_roaming",1'
  /bin/sendat "$PORT" 'AT+QCFG="ims",1'
  /bin/sendat "$PORT" 'AT+QSCLK=0,0'
  /bin/sendat "$PORT" 'AT+QMAPWAC=1'
  /bin/sendat "$PORT" "AT+QUIMSLOT=${SIMCard}"
  [ "$ResetModem" -gt 0 ] && /bin/sendat "$PORT" 'AT+CFUN=1,1'
  sleep 5
}

function MPDN() {
  WaitAT || return 1
  
  echo "$(Now) Empty MPDN ..." |tee -a "$LOG"
  /bin/sendat "$PORT" 'AT+QMAP="MPDN_rule",0'
  sleep 5

  WaitAT || return 1
  for i in $(seq 1 $MaxNum); do
    result=`/bin/sendat "$PORT" 'AT+QMAP="MPDN_rule"'`
    echo "$result" |grep -q '0,0,0,0,0'
    [ $? -eq 0 ] && break || sleep 1
    echo "$result" |grep -q '0,1,0,1,1'
    [ $? -eq 0 ] && return 1
  done

  WaitAT || return 1
  echo "$(Now) Reset MPDN ..." |tee -a "$LOG"
  /bin/sendat "$PORT" 'AT+QMAP="MPDN_rule",0,1,0,1,1,"FF:FF:FF:FF:FF:FF"'
  sleep 5

  WaitAT || return 1
  for i in $(seq 1 $MaxNum); do
    result=`/bin/sendat "$PORT" 'AT+QMAP="MPDN_rule"'`
    echo "$result" |grep -q '0,1,0,1,1'
    [ $? -eq 0 ] && break || sleep 1
    echo "$result" |grep -q '0,0,0,0,0'
    [ $? -eq 0 ] && return 1
  done
}

function WaitIPv4() {
  WaitAT || return 1
  echo "$(Now) Wait IPv4 ..." |tee -a "$LOG"
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
  echo "$(Now) Check Interface ..." |tee -a "$LOG"
  mode="${1:-0}"
  if [ "$mode" -eq 0 ]; then
    ipv4=`/bin/sendat "$PORT" 'AT+CGPADDR=1' |grep '+CGPADDR:' |cut -d',' -f2 |grep -o '[0-9\.]*'`
    [ -n "$ipv4" ] || ipv4="0.0.0.0"
    ipv4If=`ubus call network.interface.wan status |grep '"address":' |cut -d'"' -f4 |grep -o '[0-9\.]*'`
    [ -n "$ipv4If" ] || ipv4If="0.0.0.0"
    [ "$ipv4" == "$ipv4If" ] && return 0
  fi
  echo "$(Now) Reload Interface ..." |tee -a "$LOG"
  /sbin/ifup wan
  /sbin/ifup wan6
  return 0
}

# /bin/sendat 3 'AT+QSCAN=2,1'
# /bin/sendat 3 'AT'

function LockNR5G() {
  # pci:rfcn:band:scs
  echo "$(Now) NR5G Lock ..." |tee -a "$LOG"
  cell=`/bin/sendat "$PORT" 'AT+QENG="servingcell"'|grep '+QENG:' |cut -d',' -f8,10,16,11`
  echo "$(Now) NR5G Cell: $cell" |tee -a "$LOG"
  [ -n "$cell" ] || return 1
  lock="${1:-$cell}"
  echo "$(Now) NR5G Lock: $lock" |tee -a "$LOG"
  pci=`echo "$lock" |cut -d',' -f1`
  rfcn=`echo "$lock" |cut -d',' -f2`
  band=`echo "$lock" |cut -d',' -f3`
  scs=`echo "$lock" |cut -d',' -f4`
  [ "$lock" != "$cell" ] && {
      meas=`/bin/sendat "$PORT" 'AT+QNWCFG="nr5g_meas_info"' |grep '+QNWCFG:' |cut -d',' -f4,3`
      echo "$meas" |grep -q "^${rfcn},${pci}$"
      [ $? -eq 0 ] || {
          echo "$(Now) NR5G Lock: NotFoundPCI" |tee -a "$LOG"
          return 1
      }
  }
  scsHz="$(($((2**${scs}))*15))"
  /bin/sendat "$PORT" "AT+QNWLOCK=\"common/5g\",${pci},${rfcn},${scsHz},${band}" |grep -q "OK"
  [ $? -eq 0 ] && {
      echo "$(Now) NR5G: N${band}:${rfcn}:${pci}" |tee -a "$LOG"
      return 0
  } || {
      echo "$(Now) NR5G Lock: Fail" |tee -a "$LOG"
      return 1
  }
}

echo "$(Now) START" |tee -a "$LOG"

for i in $(seq 1 $MaxNum); do
  n=$(($i/2))
  m=$(($i%2))
  
  [ $m -eq 1 ] && {
    [ $n -eq 0 ] && {
      Driver "$EmptyNVRAM"
      NR5G "$BAND"
      COPS
    }
    Modem "$SIMCardIndex" "$n"
    WaitSIM
  }
  
  [ "$PCIStatic" -gt 0 ] && LockNR5G "$PCILock"
  MPDN || continue
  WaitIPv4 || continue
  
  ReloadIf && break
done

echo "$(Now) FINISH" |tee -a "$LOG"

# /bin/sendat "$PORT" 'AT+CMGL=4'
# sms_tool -s "ME" -f "%Y/%d/%m %H:%M:%S" -d /dev/ttyUSB2 -j recv


