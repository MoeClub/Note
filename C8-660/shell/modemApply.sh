#!/bin/sh

execPath=`readlink -f "$0"`
dirPath="${execPath%/*}"
modemFunc="${dirPath}/modemFunc.sh"
[ -f "${modemFunc}" ] && . "${modemFunc}" || exit 1


PORT="2"
TAG="${execPath##*/}"
SYSLOG=`Config Syslog "0"`
LOG=`Config ApplyLOG "/dev/null"`

Log "START"

Cell `Config CellMode` `Config BandNR5G` `Config BandLTE`
[ `Config StaticPCI 0` -eq "0" ] && LockNR5G "0"
[ `Config StaticPCI 0` -gt "0" ] && LockNR5G `Config LockPCINR5G`
Modem `Config SIMCard 1` "0"
ResetNVRAM `Config ResetNVRAM 0`

Log "FINISH"
exit 0

