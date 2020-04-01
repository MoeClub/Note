#!/bin/bash

Media="$1"
ForceH264="${2:-0}"
Uploader="upload.sh"
M3u8mod="m3u8.sh"
Publish="publish.sh"
BitRadio="1.55"
ForceBitRadio="1.75"
ForceMaxRadio="1.20"
ForceRate="2400000"
MaxSize=5
MaxCheck=10
MaxTime=10
AutoClear=0
QuickMode=1


# Main
if [ -n "${Media}" ] && [ -f "${Media}" ]; then
  echo "$ForceH264" |grep -q "^-"
  [ "$?" -eq 0 ] && QuickMode=0
  ForceH264=`echo "$ForceH264" |grep -o "[0-9]\{1,\}"`
  [ -n "$ForceH264" ] || ForceH264=0
  echo "media file: '${Media}'."
else
  [ -n "${Media}" ] && echo "Not found '${Media}'." || echo "Please input a media file."
  exit 1
fi

MediaName=`basename "${Media}" |cut -d'.' -f1 |sed 's/[[:space:]]/_/g'`
ScriptDir=`dirname $0`
CurrentDir=`pwd`
OutPutM3u8="${CurrentDir}/${MediaName}.m3u8"
OutPutM3u8Bak="${CurrentDir}/${MediaName}.m3u8.bak"
OutPutLog="${CurrentDir}/${MediaName}.log"
MediaFolder="${CurrentDir}/${MediaName}.output"

# cache
[ "$QuickMode" == 1 ] && [ -f "${OutPutM3u8Bak}" ] && [ -d "${MediaFolder}" ] || QuickMode=0
if [ "$QuickMode" != 1 ]; then
  rm -rf "${OutPutLog}"
  rm -rf "${MediaFolder}"
  mkdir -p "${MediaFolder}"
else
  rm -rf "${OutPutLog}"
fi

## m3u8
if [ "$QuickMode" != 1 ]; then
  BitRate=`ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "${Media}"`
  echo "media bitrate: ${BitRate}"
  if [ "$ForceH264" -eq 0 ]; then
    _ForceH264=`awk 'BEGIN{print '${BitRate}' / ('${ForceBitRadio}' * '${ForceRate}')}' |cut -d'.' -f1`
    [ "$_ForceH264" -ne 0 ] && ForceH264=1
  fi
  if [ "$ForceH264" -ge 2 ]; then
    MediaCode=`ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "${Media}" |sort |uniq`
    if [ "$MediaCode" != "h264" ]; then
      echo "Error: This media file code '${MediaCode}', must 'h264' in this mode."
      exit 1
    fi
    VideoCode="copy"
    VideoAddon="-bsf:v h264_mp4toannexb"
    [ "$ForceH264" -le 2 ] && VideoTime="2" || VideoTime="$ForceH264"
  elif [ "$ForceH264" -eq 1 ]; then
    ForceMaxRate=`awk 'BEGIN{print '${ForceRate}' * '${ForceMaxRadio}'}' |cut -d'.' -f1`
    ForceBuf=`awk 'BEGIN{print '${ForceRate}' / '${ForceMaxRadio}'}' |cut -d'.' -f1`
    VideoAddon="-b:v ${ForceRate} -maxrate ${ForceMaxRate} -bufsize ${ForceBuf}"
    VideoCode="h264"
    if [ "$BitRate" -gt "3500000" ]; then
      BitRadio="${ForceBitRadio}"
    fi
    BitRate=3000000
    echo "media bitrate(new): ${BitRate}"
  else
    MediaCode=`ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "${Media}" |sort |uniq`
    if [ "$MediaCode" == "h264" ]; then
      VideoCode="copy"
    else
      VideoCode="h264"
    fi
    if [ "$VideoCode" == "copy" ]; then
      VideoAddon="-bsf:v h264_mp4toannexb"
    else
      if [ "$BitRate" -gt "3500000" ]; then
        BitRadio="${ForceBitRadio}"
        BitRate=3000000
      else
        ForceRate="${BitRate}"
        BitRate=`awk 'BEGIN{print '${ForceRate}' * '${ForceBitRadio}'}' |cut -d'.' -f1`      
      fi
      echo "media bitrate(new): ${BitRate}"
      ForceMaxRate=`awk 'BEGIN{print '${ForceRate}' * '${ForceMaxRadio}'}' |cut -d'.' -f1`
      ForceBuf=`awk 'BEGIN{print '${ForceRate}' / '${ForceMaxRadio}'}' |cut -d'.' -f1`
      VideoAddon="-b:v ${ForceRate} -maxrate ${ForceMaxRate} -bufsize ${ForceBuf}"
    fi
  fi
  if [ "$ForceH264" -le 1 ]; then
    VideoTime=`awk 'BEGIN{print ('${MaxSize}' * 1024 * 1024 * 8) / ('${BitRate}' * '${BitRadio}') }' |cut -d'.' -f1`
    if [ -n "$VideoTime" ]; then
      if [ "${BitRate}" -gt 3500000 ]; then
        MaxTime=5
      elif [ "${BitRate}" -gt 3000000 ]; then
        MaxTime=7
      fi
      if [ "$VideoTime" -gt "$MaxTime" ]; then
        VideoTime="$MaxTime"
      fi
    else
      exit 1
    fi
  fi
  echo "media segment time: ${VideoTime}"
  ffmpeg -v info -i "${Media}" -vcodec ${VideoCode} -acodec aac -strict experimental ${VideoAddon} -map 0:v:0 -map 0:a? -f segment -segment_list "${OutPutM3u8}" -segment_time "${VideoTime}" "${MediaFolder}/output_%04d.ts"
  if [ $? -ne 0 ]; then
    exit 1
  else
    cp -rf "${OutPutM3u8}" "${OutPutM3u8Bak}"
  fi
else
  cp -rf "${OutPutM3u8Bak}" "${OutPutM3u8}"
fi

## upload
echo "start upload..."
if [ -e "${ScriptDir}/${Uploader}" ]; then
  bash "${ScriptDir}/${Uploader}" "${MediaFolder}" |tee -a "${OutPutLog}"
  ## mod m3u8
  if [ -f "${ScriptDir}/${M3u8mod}" ]; then
    bash "${ScriptDir}/${M3u8mod}" "${OutPutLog}" "${OutPutM3u8}"
  fi
fi

# check
echo "check upload..."

function ForceVBR(){
  fsName="$1"
  loopTimes="$2"
  [ -n "${fsName}" ] && [ -f "${fsName}" ] || return
  [ `du -s -k "${fsName}" |cut -f1` -le `awk 'BEGIN{print '${MaxSize}' * 1024}' |cut -d'.' -f1` ] && return
  NewFsName="${fsName}_New.ts"
  cp -rf "${fsName}" "${NewFsName}"
  LowerRadio=`awk 'BEGIN{print 0.85 ** '${loopTimes}'}'`
  NewForceRate=`awk 'BEGIN{print '${ForceRate}' * '${LowerRadio}'}' |cut -d'.' -f1`
  NewForceMaxRate=`awk 'BEGIN{print '${NewForceRate}' * '${ForceMaxRadio}'}' |cut -d'.' -f1`
  NewForceBuf=`awk 'BEGIN{print '${NewForceRate}' / '${ForceMaxRadio}'}' |cut -d'.' -f1`
  VideoAddon="-b:v ${NewForceRate} -maxrate ${NewForceMaxRate} -bufsize ${NewForceBuf}"
  ffmpeg -y -v info -i "${NewFsName}" -vcodec h264 -acodec copy -strict experimental -bsf:v h264_mp4toannexb ${VideoAddon} -f mpegts "${fsName}"
  [ -f "${NewFsName}" ] && [ -f "${fsName}" ] && rm -rf "${NewFsName}"
}

for((i=0; i<$MaxCheck; i++)); do
  BadCheck=`grep -v "^#\|^https\?://" "${OutPutM3u8}"`
  [ -n "$BadCheck" ] || break
  for Item in `echo "$BadCheck"`; do
    if [ -f "${Item}" ]; then
      BadItem="${Item}"
    elif [ -f "${MediaFolder}/${Item}" ]; then
      BadItem="${MediaFolder}/${Item}"
    else
      echo "Error: not found '${Item}'."
      exit 1
    fi
    ForceVBR "${BadItem}" "${i}"
    bash "${ScriptDir}/${Uploader}" "${BadItem}" |tee -a "${OutPutLog}"
  done
  sed -i '/;\ NULL_/d' "${OutPutLog}"
  ## mod m3u8
  if [ -f "${ScriptDir}/${M3u8mod}" ]; then
    bash "${ScriptDir}/${M3u8mod}" "${OutPutLog}" "${OutPutM3u8}"
  fi
done

# publish
if [ -f "${ScriptDir}/${Publish}" ]; then
  echo "publish ..."
  bash "${ScriptDir}/${Publish}" "${OutPutM3u8}"
fi

# clear
if [ "$AutoClear" != 0 ]; then
  rm -rf "${OutPutLog}"
  rm -rf "${MediaFolder}"
  rm -rf "${OutPutM3u8Bak}"
fi
