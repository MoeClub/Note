#!/bin/sh

PORT="3"
MaxNum=30
LOG="/tmp/notice.log"
# LOG="/dev/null"

BarkURL=""

NoticePID="/tmp/NoticePID"
Device="/dev/ttyUSB${PORT}"

function Now() {
  echo -ne `date '+[%Y/%m/%d %H:%M:%S']`
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
    if [ -e "${Device}" ]; then
      /bin/sendat "$PORT" 'AT' |grep -q 'OK'
      [ $? -eq 0 ] && return 0
    fi
    sleep 1 
  done
  return 1
}

function WaitIPv4() {
  WaitAT || return 1
  echo "$(Now) Wait IPv4 ..." |tee -a "$LOG"
  for i in $(seq 1 $MaxNum); do
    ipv4=`/bin/sendat "$PORT" 'AT+CGPADDR=1' |grep '+CGPADDR:' |cut -d',' -f2 |grep -o '[0-9\.]*'`
    [ -n "$ipv4" ] && [ "$ipv4" != "0.0.0.0" ] && echo "$(Now) IPv4: $ipv4" |tee -a "$LOG" && return 0
    sleep 1
  done
  return 1
}

function ReloadWAN() {
  echo "$(Now) New Network ..." |tee -a "$LOG"
  CheckLED 0
  WaitIPv4 || return 1
  echo "$(Now) Check Interface ..." |tee -a "$LOG"
  CheckLED 1
  ipv4=`/bin/sendat "$PORT" 'AT+CGPADDR=1' |grep '+CGPADDR:' |cut -d',' -f2 |grep -o '[0-9\.]*'`
  [ -n "$ipv4" ] || ipv4="0.0.0.0"
  ipv4If=`ubus call network.interface.wan status |grep '"address":' |cut -d'"' -f4 |grep -o '[0-9\.]*'`
  [ -n "$ipv4If" ] || ipv4If="0.0.0.0"
  [ "$ipv4" == "$ipv4If" ] && return 0
  echo "$(Now) Reload Interface ..." |tee -a "$LOG"
  ubus call network.interface.wan down
  ubus call network.interface.wan up
  ubus call network.interface.wan6 down
  ubus call network.interface.wan6 up
}

function CheckLED() {
  NR5G="hc:blue:cmode5"
  LTE="hc:blue:cmode4"
  STATUS=0
  echo "$(Now) Check Network Mode ..." |tee -a "$LOG"
  LED_NR5G="/sys/devices/platform/gpio-leds/leds/${NR5G}/brightness"
  LED_LTE="/sys/devices/platform/gpio-leds/leds/${LTE}/brightness"
  echo 0 >"$LED_NR5G"
  echo 0 >"$LED_LTE"
  [ $1 -eq 0 ] && return "$STATUS"
  result=`/bin/sendat "$PORT" 'AT+QRSRQ'`
  net=`echo "${result##*,}" |grep -o 'NR5G\|LTE'`
  [ "$net" == "NR5G" ] && echo 1 >"$LED_NR5G" && STATUS=1
  [ "$net" == "LTE" ] && echo 1 >"$LED_LTE" && STATUS=1
  return "$STATUS"
}

function NewSMS() {
  echo "$(Now) New SMS ..." |tee -a "$LOG"
  data=`sms_tool -f '%Y/%m/%d %H:%M:%S' -j -u recv`
  SMSWithBark "$data"
}

function SMSWithBark() {
  echo "$(Now) SMS With Bark ..." |tee -a "$LOG"
  data="${1:-}"
  [ -n "$data" ] || return 1
  length=`echo "$data" |jq '.msg |length'`
  [ $length -gt 0 ] || return 1
  i=0
  while [ $i -lt $length ]; do
    item=`echo "$data" |jq -c ".msg[$i]"`
    echo "$(Now) SMS: $item" |tee -a "$LOG"
    sender=`echo "$item" |jq -r ".sender"`
    timestamp=`echo "$item" |jq -r ".timestamp"`
    content=`echo "$item" |jq -r ".content"`
    title="[${timestamp}] ${sender}"
    BarkService "$title" "$content"
    i=$(($i+1))
  done
}

function BarkService() {
  [ -n "$BarkURL" ] || return 1
  title=`echo "$1" |jq -sRr @uri`
  body=`echo "$2" |jq -sRr @uri`
  url="${BarkURL%/}/${title}/${body}"
  curl -ksSL --connect-timeout 5 -X GET "${url}" >/dev/null 2>&1 &
}

DeadPID "$NoticePID" || exit 1
echo "$$" >"$NoticePID"
CheckLED 1
while true; do
  WaitAT || {
  	sleep 5
  	continue
  }
  while IFS= read -r line; do
    echo -ne "$line" |grep -q '+CMTI:\s*"ME"\|+C5GREG:\s*[15]\|+CREG:\s*[15]'
    [ $? -eq 0 ] || continue
    var=`echo -ne "${line%%:*}"`
    case $var in
      +CMTI)
        NewSMS;
        ;;
      +CREG|+C5GREG)
        ReloadWAN;
        ;;
      *)
        ;;
    esac
  done < "${Device}"
done
