#!/bin/sh

execPath=`readlink -f "$0"`
dirPath="${execPath%/*}"
modemFunc="${dirPath}/modemFunc.sh"
[ -f "${modemFunc}" ] && . "${modemFunc}" || exit 1


PORT="2"
TAG="${execPath##*/}"
SYSLOG=`Config Syslog "0"`
LOG=`Config InitLOG "/dev/null"`
MaxNum=`Config MaxNum "120"`
Notice=`Config NoticeFile`
NoticePID=`Config NoticePID "/tmp/run/modemNotice.pid"`


Log "START"

[ -n "${Notice}" ] && {
  NoticeFile="${dirPath}/${Notice}"
  [ -f "$NoticeFile"  ] && {
      DeadPID "$NoticePID" && {
        /bin/sh "$NoticeFile" >/dev/null 2>&1 &
        Log "Notice PID: $!"
      }
  }
}

for i in $(seq 1 $MaxNum); do
  n=$(($i/2))
  m=$(($i%2))
  
  [ $m -eq 1 ] && {
    [ $n -eq 0 ] && {
      Driver
      Cell `Config CellMode` `Config BandNR5G` `Config BandLTE`
      COPS || continue
    }
    Modem `Config SIMCard 1` "$n"
    WaitSIM
  }
  
  [ `Config StaticPCI 0` -eq "0" ] && LockNR5G "0"
  [ `Config StaticPCI 0` -gt "0" ] && LockNR5G `Config LockPCINR5G`
  
  MPDN && break || continue
  
done

Log "FINISH"
exit 0
