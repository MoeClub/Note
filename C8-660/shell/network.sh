#!/bin/sh

execPath=`readlink -f "$0"`
dirPath="${execPath%/*}"
modemFunc="${dirPath}/modemFunc.sh"
[ -f "${modemFunc}" ] && . "${modemFunc}" || exit 1


PORT="2"
MaxNum=`Config MaxNum "120"`
LOG=`Config NetworkLOG "/dev/null"`
Notice=`Config NoticeFile`
NoticePID=`Config NoticePID "/tmp/NoticePID"`


echo "$(Now) START" |tee -a "$LOG"

for i in $(seq 1 $MaxNum); do
  n=$(($i/2))
  m=$(($i%2))
  
  [ $m -eq 1 ] && {
    [ $n -eq 0 ] && {
      Driver
      NR5G `Config BandNR5G`
      COPS
    }
    Modem `Config SIMCard 1` "$n"
    WaitSIM
  }
  
  [ `Config StaticPCI 0` -gt "0" ] && LockNR5G `Config LockPCI`
  MPDN || continue
  
  ReloadWAN && break || continue
done

[ -n "${Notice}" ] && {
  NoticeFile="${dirPath}/${Notice}"
  [ -f "$NoticeFile"  ] && {
      DeadPID "$NoticePID" && {
        /bin/sh "$NoticeFile" >/dev/null 2>&1 &
        echo "$(Now) Notice PID: $!" |tee -a "$LOG"
      }
  }
}

echo "$(Now) FINISH" |tee -a "$LOG"
exit 0
