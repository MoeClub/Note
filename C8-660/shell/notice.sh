#!/bin/sh

execPath=`readlink -f "$0"`
dirPath="${execPath%/*}"
modemFunc="${dirPath}/modemFunc.sh"
[ -f "${modemFunc}" ] && . "${modemFunc}" || exit 1


PORT="3"
MaxNum=`Config MaxNum "120"`
LOG=`Config NoticeLOG "/dev/null"`
NoticePID=`Config NoticePID "/tmp/NoticePID"`


DeadPID "$NoticePID" || exit 1
echo "$$" >"$NoticePID"
ResetLED 1
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
  done < "/dev/ttyUSB${PORT}"
done
