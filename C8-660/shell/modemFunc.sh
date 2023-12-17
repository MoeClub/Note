#!/bin/sh

[ -e /bin/sendat ] || exit 1
# Log with logger
SYSLOG="0"

# Log with echo
LOG="/dev/null"


[ -f /etc/config/modem ] || touch /etc/config/modem
Entry="modem.@network[-1]"
uci -q get "${Entry}" >/dev/null 2>&1 || {
  uci -q add modem network
  # Use SIM Card Index
  uci -q set "${Entry}.SIMCard"="1"
  # Lock PCI, If LockPCI is empty, will lock first PCI.
  uci -q set "${Entry}.StaticPCI"="0"
  # CellMode="", CellMode="NR5G", CellMode="NR5G:LTE:WCDMA"
  uci -q set "${Entry}.CellMode"=""
  # BAND="", BAND="78", BAND="1:78"
  uci -q set "${Entry}.BandNR5G"=""
  # BAND="", BAND="3", BAND="1:3"
  uci -q set "${Entry}.BandLTE"=""
  # LockPCINR5G="<PCI>,<RFCN>,<BAND>,<SCS>"
  uci -q set "${Entry}.LockPCINR5G"=""
  # Network Init Log File
  uci -q set "${Entry}.InitLOG"="/tmp/log/modemInit"
  # Network Apply Log File
  uci -q set "${Entry}.ApplyLOG"="/tmp/log/modemApply"
  # Notice File Name
  uci -q set "${Entry}.NoticeFile"="modemNotice.sh"
  # Notice Log File
  uci -q set "${Entry}.NoticeLOG"="/tmp/log/modemNotice"
  # Notice PID File
  uci -q set "${Entry}.NoticePID"="/tmp/run/modemNotice.pid"
  # Send SMS With Bark
  uci -q set "${Entry}.BarkURL"=""
  # Try Max Times
  uci -q set "${Entry}.MaxNum"="120"
  # Reset NVRAM
  uci -q set "${Entry}.ResetNVRAM"="0"
  # Log with syslog
  uci -q set "${Entry}.Syslog"="1"
  uci commit modem
}

function Config() {
  key="${1:-}"
  default="${2:-}"
  [ -n "$key" ] || echo -ne ""
  result=`uci -q get "${Entry}.${key}" 2>/dev/null`
  [ -n "$result" ] && echo -ne "$result" || echo -ne "$default"
}

function ConfigSet() {
  key="${1:-}"
  value="${2:-}"
  [ -n "$key" ] && [ -n "$value" ] || return 1
  uci -q set "${Entry}.${key}=${value}" 2>/dev/null
  [ "$?" -eq "0" ] && uci commit modem || return 1
  return 0
}

function Now() {
  echo -ne `date '+[%Y/%m/%d %H:%M:%S']`
}

function Log() {
  [ "${SYSLOG}" == "1" ] && [ -n "${TAG}" ] && logger -s -p "daemon.notice" -t "${TAG}" "$1" || echo "$(Now) $1" |tee -a "${LOG}"
}

function DeadPID() {
  [ -n "$1" ] && [ -f "$1" ] || return 0
  pid=`cat "$1" |grep -o '[0-9]*'`
  [ -n "$pid" ] || return 0
  ps |sed 's/^[[:space:]]*//' |cut -d' ' -f1 |grep -q "^${pid}$"
  [ $? -eq 0 ] && return 1 || return 0
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
  Log "Wait SIM ..."
  for i in $(seq 1 $MaxNum); do
    stat=`/bin/sendat "$PORT" 'AT+QINISTAT' |grep '+QINISTAT:' |grep -o '[0-9]*'`
    Log "SIM Satus: $stat"
    [ "$stat" -ne 7 ] && sleep 1 && continue || break 
   done
}

function Driver(){
  Log "Config Driver ..."
  /bin/sendat "$PORT" 'AT+QCFG="pcie/mode",1'
  /bin/sendat "$PORT" 'AT+QCFG="data_interface",1,0'
  /bin/sendat "$PORT" 'AT+QETH="eth_driver","r8168",0'
  /bin/sendat "$PORT" 'AT+QETH="eth_driver","r8125",1'
  /bin/sendat "$PORT" 'AT+QCFG="volte_disable",0'
  /bin/sendat "$PORT" 'AT+QCFG="sms_control",1,1'
  /bin/sendat "$PORT" 'AT+QCFG="call_control",0,0'
  /bin/sendat "$PORT" 'AT+QNWCFG="nr5g_meas_info",1' 
  /bin/sendat "$PORT" 'AT+CPMS="ME","ME","ME"'
  /bin/sendat "$PORT" 'AT+CGEREP=2,1'
  /bin/sendat "$PORT" 'AT+CREG=1'
  /bin/sendat "$PORT" 'AT+C5GREG=1'
}

function ResetNVRAM() {
  [ -n "$PORT" ] || return 1
  flag="${1:-0}"
  if [ "$flag" != "0" ]; then
      ConfigSet ResetNVRAM 0
  fi
  if [ "$flag" == "1" ]; then
      Log "Reset NVRAM ..."
      /bin/sendat "$PORT" 'AT+QPRTPARA=3'
  fi
  return 0
}

function Cell(){
  rfBand=`/bin/sendat "$PORT" 'AT+QNWPREFCFG="rf_band"'`
  rfNR5G=`echo "$rfBand" |grep '+QNWPREFCFG:\s*"nr5g_band"' |cut -d',' -f2 |grep -o '[0-9A-Za-z:]*'`
  rfLTE=`echo "$rfBand" |grep '+QNWPREFCFG:\s*"lte_band"' |cut -d',' -f2 |grep -o '[0-9A-Za-z:]*'`
  cellMode="${1:-NR5G:LTE:WCDMA}"
  nr5gBand="${2:-$rfNR5G}"
  lteBand="${3:-$rfLTE}"
  /bin/sendat "$PORT" 'AT+QNWPREFCFG="rat_acq_order",NR5G:LTE:WCDMA'
  /bin/sendat "$PORT" 'AT+QNWPREFCFG="nr5g_disable_mode",2'
  Log "Set Cell Mode ${cellMode}"
  /bin/sendat "$PORT" "AT+QNWPREFCFG=\"mode_pref\",${cellMode}"
  Log "Set NR5G ${nr5gBand} ..."
  /bin/sendat "$PORT" "AT+QNWPREFCFG=\"nr5g_band\",${nr5gBand}"
  Log "Set LTE ${lteBand} ..."
  /bin/sendat "$PORT" "AT+QNWPREFCFG=\"lte_band\",${lteBand}"
}

function LockNR5G() {
  [ "$1" == "0" ] && {
      Log "NR5G Lock Release ..."
      /bin/sendat "$PORT" 'AT+QNWLOCK="common/4g",0' >/dev/null 2>&1
      /bin/sendat "$PORT" 'AT+QNWLOCK="common/5g",0' >/dev/null 2>&1
      return 0
  }
  # pci:rfcn:band:scs
  Log "Config Lock NR5G ..."
  cell=`/bin/sendat "$PORT" 'AT+QENG="servingcell"'|grep '+QENG:' |grep 'NR5G' |cut -d',' -f8,10,16,11`
  Log "NR5G Cell: $cell"
  [ -n "$cell" ] || return 1
  lock="${1:-$cell}"
  Log "NR5G Lock: $lock"
  pci=`echo "$lock" |cut -d',' -f1`
  rfcn=`echo "$lock" |cut -d',' -f2`
  band=`echo "$lock" |cut -d',' -f3`
  scs=`echo "$lock" |cut -d',' -f4`
  [ "$lock" != "$cell" ] && {
      meas=`/bin/sendat "$PORT" 'AT+QNWCFG="nr5g_meas_info"' |grep '+QNWCFG:' |cut -d',' -f4,3`
      echo "$meas" |grep -q "^${rfcn},${pci}$"
      [ $? -eq 0 ] || {
          Log "NR5G Lock: NotFoundPCI"
          return 1
      }
  }
  scsHz="$(($((2**${scs}))*15))"
  /bin/sendat "$PORT" "AT+QNWLOCK=\"common/5g\",${pci},${rfcn},${scsHz},${band}" |grep -q "OK"
  [ $? -eq 0 ] && {
      Log "NR5G: N${band}:${rfcn}:${pci}"
      return 0
  } || {
      Log "NR5G Lock: Fail"
      return 1
  }
}

function COPS(){
  Log "Search COPS ..."
  /bin/sendat "$PORT" 'AT+COPS=2'
  /bin/sendat "$PORT" 'AT+COPS=0'
  maxNum=$(($MaxNum/4))
  for i in $(seq 1 $maxNum); do
    cops=`/bin/sendat "$PORT" 'AT+COPS?' |grep '+COPS: 0,'  |cut -d'"' -f2 |sed 's/[[:space:]]//g'`
    [ -n "$cops" ] && Log "COPS: $cops" && return 0 || sleep 1
  done
  return 1
}

function Modem(){
  Log "Config Modem ..."
  simCard="${1:-1}"
  resetModem="${2:-0}"
  /bin/sendat "$PORT" 'AT+QNWPREFCFG="roam_pref",255'
  /bin/sendat "$PORT" 'AT+QNWCFG="data_roaming",1'
  /bin/sendat "$PORT" 'AT+QCFG="ims",1'
  /bin/sendat "$PORT" 'AT+QSCLK=0,0'
  /bin/sendat "$PORT" 'AT+QMAPWAC=1'
  /bin/sendat "$PORT" "AT+QUIMSLOT=${simCard}"
  [ "$resetModem" -gt 0 ] && {
    sleep 5
    Log "Restart Modem ..."
    /bin/sendat "$PORT" 'AT+CFUN=1,1'
  }
  sleep 5
}

function MPDN() {
  WaitAT || return 1
  
  Log "Empty MPDN ..."
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
  Log "Reset MPDN ..."
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
  Log "Wait IPv4 ..."
  maxNum=$(($MaxNum/4))
  for i in $(seq 1 $maxNum); do
    ipv4=`/bin/sendat "$PORT" 'AT+CGPADDR=1' |grep '+CGPADDR:' |cut -d',' -f2 |grep -o '[0-9\.]*'`
    [ -n "$ipv4" ] && [ "$ipv4" != "0.0.0.0" ] && Log "IPv4: $ipv4" && return 0
    sleep 1
  done
  return 1
}

function ReloadWAN() {
  Log "New Network ..."
  ResetLED 0
  WaitIPv4 || return 1
  Log "Check Interface ..."
  ResetLED 1
  ipv4If=`ubus call network.interface.wan status |grep '"address":' |cut -d'"' -f4 |grep -o '[0-9\.]*'`
  [ -n "$ipv4If" ] || ipv4If="0.0.0.0"
  ipv4=`/bin/sendat "$PORT" 'AT+CGPADDR=1' |grep '+CGPADDR:' |cut -d',' -f2 |grep -o '[0-9\.]*'`
  [ -n "$ipv4" ] || ipv4="0.0.0.0"
  [ "$ipv4" == "$ipv4If" ] && return 0
  Log "Reload Interface ..."
  ubus call network.interface.wan down
  ubus call network.interface.wan up
  ubus call network.interface.wan6 down
  ubus call network.interface.wan6 up
  return 0
}

function ResetLED() {
  STATUS=0
  NR5G="hc:blue:cmode5"
  LTE="hc:blue:cmode4"
  LED_NR5G="/sys/devices/platform/gpio-leds/leds/${NR5G}/brightness"
  LED_LTE="/sys/devices/platform/gpio-leds/leds/${LTE}/brightness"
  echo 0 >"$LED_NR5G"
  echo 0 >"$LED_LTE"
  [ $1 -eq 0 ] && {
      Log "Reset LED ..."
      return "$STATUS"
  }
  result=`/bin/sendat "$PORT" 'AT+QRSRQ'`
  net=`echo "${result##*,}" |grep -o 'NR5G\|LTE'`
  [ "$net" == "NR5G" ] && echo 1 >"$LED_NR5G" && STATUS=1
  [ "$net" == "LTE" ] && echo 1 >"$LED_LTE" && STATUS=1
  Log " Network Mode: ${net:-NULL}"
  return "$STATUS"
}

function NewSMS() {
  Log "New SMS ..."
  data=`sms_tool -f '%Y/%m/%d %H:%M:%S' -j -u recv`
  HandlerSMS "$data"
}

function HandlerSMS() {
  Log "SMS Handler ..."
  data="${1:-}"
  [ -n "$data" ] || return 1
  length=`echo "$data" |jq '.msg |length'`
  [ $length -gt 0 ] || return 1
  i=0
  while [ $i -lt $length ]; do
    item=`echo "$data" |jq -c ".msg[$i]"`
    Log "SMS: $item"
    sender=`echo "$item" |jq -r ".sender"`
    timestamp=`echo "$item" |jq -r ".timestamp"`
    content=`echo "$item" |jq -r ".content"`
    title="[${timestamp}] ${sender}"
    BarkService "$title" "$content"
    i=$(($i+1))
  done
}

function BarkService() {
  BarkURL=`Config BarkURL`
  [ -n "$BarkURL" ] || return 1
  Log "SMS With Bark ..."
  title=`echo "$1" |jq -sRr @uri`
  body=`echo "$2" |jq -sRr @uri`
  url="${BarkURL%/}/${title}/${body}"
  curl -ksSL --connect-timeout 5 -X GET "${url}" >/dev/null 2>&1 &
}

