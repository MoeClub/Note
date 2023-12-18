#!/bin/sh

PORT=2

. /usr/share/libubox/jshn.sh


function ATI() {
  ret=`/bin/sendat "$PORT" 'ATI' |grep -v "^+" |tr -d '\r'`
  var=`echo "$ret" |sed -n '1p'`
  if [ "$var" == "ATI" ]; then
    var0=`echo "$ret" |sed -n '2p'`
    var1=`echo "$ret" |sed -n '3p'`
    var2=`echo "$ret" |sed -n '4p' |sed 's/[[:space:]]//g' |cut -d':' -f2`
  fi
  [ -n "$var0" ] || var0="-"
  [ -n "$var1" ] || var1="-"
  [ -n "$var2" ] || var2="-"
  var3=`/bin/date '+%Y/%d/%m %H:%M:%S'`
  [ -n "$var3" ] || var3="-"
  var4=`/bin/sendat "$PORT" 'AT+QTEMP' |grep '+QTEMP:' |grep 'aoss-0-usr\|mdm-q6-usr\|ipa-usr\|cpu0-a7-usr\|mdm-core-usr\|modem-ambient-usr' |cut -d',' -f2 |grep -o '[0-9\-]*' |sort -n -r |head -n1`
  [ -n "$var4" ] && var4="${var4}°C" || var4="-"
  json_add_string "modem" "${var0} ${var1}"
  json_add_string "firmware" "${var2}"
  json_add_string "date" "${var3}"
  json_add_string "temp" "${var4}"
}

function SIM() {
  simIndex=`/bin/sendat "$PORT" 'AT+QUIMSLOT?' |grep '+QUIMSLOT:' |cut -d':' -f2 |grep -o '[0-9]*'`
  [ -n "$simIndex" ] || simIndex="-"
  json_add_string "simIndex" "${simIndex}"
  cops=`/bin/sendat "$PORT" 'AT+COPS?' |grep '+COPS:' |cut -d',' -f3 |tr -d '"'`
  [ -n "$cops" ] || cops="-"
  json_add_string "cops" "${cops}"
  phone=`/bin/sendat "$PORT" 'AT+CNUM' |grep '+CNUM:' |cut -d',' -f2 |grep -o '[0-9\+]*'`
  [ -n "$phone" ] || phone="-"
  json_add_string "phone" "${phone}"
  imei=`/bin/sendat "$PORT" 'AT+CGSN' |sed -n '2p' |tr -d '\r'`
  [ -n "$imei" ] || imei="-"
  json_add_string "imei" "${imei}"
  imsi=`/bin/sendat "$PORT" 'AT+CIMI' |sed -n '2p' |tr -d '\r'`
  [ -n "$imsi" ] || imsi="-"
  json_add_string "imsi" "${imsi}"
  iccid=`/bin/sendat "$PORT" 'AT+CCID' |grep '+CCID:' |tr -d '\r' |sed 's/[[:space:]]//g' |cut -d':' -f2`
  [ -n "$iccid" ] || iccid="-"
  json_add_string "iccid" "${iccid}"
}

function NET() {
  nr_bandwidth="5;10;15;20;25;30;40;50;60;70;80;90;100;200;400"
  lte_bandwidth="1.4;3;5;10;15;20"
  cell=`/bin/sendat "$PORT" 'AT+QENG="servingcell"' |grep '+QENG:' |sed 's/,/\n/g' |tr -d '"'`
  net=`echo "$cell" |sed -n '3p'`
  if [ -n "$net" ]; then
    if [ "$net" == "WCDMA" ]; then
      rfcn=`echo "$cell" |sed -n '8p'`
    elif [ "$net" == "LTE" ]; then
      var=`echo "$cell" |sed -n '4p'`
      net="${net} ${var}"
      pci=`echo "$cell" |sed -n '8p'`
      rfcn=`echo "$cell" |sed -n '9p'`
      band=`echo "$cell" |sed -n '10p'`
      var=`echo "$cell" |sed -n '11p'`
      var_ul=`echo "$lte_bandwidth" |sed 's/;/\n/g' |sed -n "$(($var+1))p"`
      var=`echo "$cell" |sed -n '12p'`
      var_dl=`echo "$lte_bandwidth" |sed 's/;/\n/g' |sed -n "$(($var+1))p"`
      band="B${band} [${var_dl}MHz/${var_ul}MHz]"
      rsrp=`echo "$cell" |sed -n '14p'`
      rsrq=`echo "$cell" |sed -n '15p'`
      sinr_x=`echo "$cell" |sed -n '17p'`
      sinr="$(($((${sinr_x}*2))-20))"
    elif [ "$net" == "NR5G-SA" ]; then
      var=`echo "$cell" |sed -n '4p'`
      net="${net} ${var}"
      pci=`echo "$cell" |sed -n '8p'`
      rfcn=`echo "$cell" |sed -n '10p'`
      band=`echo "$cell" |sed -n '11p'`
      var=`echo "$cell" |sed -n '12p'`
      var_dl=`echo "$nr_bandwidth" |sed 's/;/\n/g' |sed -n "$(($var+1))p"`
      band="N${band} [${var_dl}MHz]"
      rsrp=`echo "$cell" |sed -n '13p'`
      rsrq=`echo "$cell" |sed -n '14p'`
      sinr=`echo "$cell" |sed -n '15p'`
    fi
  fi
  [ -n "$net" ] || net="-"
  json_add_string "net" "${net}"
  [ -n "$pci" ] || pci="-"
  json_add_string "pci" "${pci}"
  [ -n "$rfcn" ] || rfcn="-"
  json_add_string "rfcn" "${rfcn}"
  [ -n "$band" ] || band="-"
  json_add_string "band" "${band}"
  [ -n "$rsrp" ] || rsrp="-"
  json_add_string "rsrp" "${rsrp}"
  [ -n "$rsrq" ] || rsrq="-"
  json_add_string "rsrq" "${rsrq}"
  [ -n "$sinr" ] || sinr="-"
  json_add_string "sinr" "${sinr}"
}

json_init

ATI
SIM
NET

json_dump

