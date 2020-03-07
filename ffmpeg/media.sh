#!/bin/bash

Media="$1"
ForceH264="${2:-0}"
Uploader="upload.sh"
M3u8mod="m3u8.sh"
Publish="publish.sh"
MaxSize=20
MaxCheck=10
MaxTime=15
BitRadio="1.55"
ForceBitRadio="1.75"
ForceMaxRadio="1.20"
ForceRate="2400000"

# Main
if [ -n "${Media}" ] && [ -f "${Media}" ]; then
  echo "media file: '${Media}'."
else
  echo "Not found '${Media}'."
  exit 1
fi

MediaName=`basename "${Media}" |cut -d'.' -f1 |sed 's/[[:space:]]/_/g'`
ScriptDir=`dirname $0`
CurrentDir=`pwd`
OutPutM3u8="${CurrentDir}/${MediaName}.m3u8"
OutPutLog="${CurrentDir}/${MediaName}.log"
MediaFolder="${CurrentDir}/${MediaName}.output"

# cache
rm -rf "${OutPutLog}"
rm -rf "${MediaFolder}"
mkdir -p "${MediaFolder}"

## m3u8
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
  [ "$ForceH264" -le 3 ] && VideoTime="3" || VideoTime="$ForceH264"
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
      MaxTime=10
    fi
    if [ "$VideoTime" -gt "$MaxTime" ]; then
      VideoTime="$MaxTime"
    fi
  else
    exit 1
  fi
fi
echo "media segment time: ${VideoTime}"
ffmpeg -v info -i "${Media}" -vcodec ${VideoCode} -acodec aac -strict experimental ${VideoAddon} -map 0:v:0 -map 0:a? -f segment -segment_list "${OutPutM3u8}" -segment_time ${VideoTime} "${MediaFolder}/output_%04d.ts"
if [ $? -ne 0 ]; then
  exit 1
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
    bash "${ScriptDir}/${Uploader}" "${BadItem}" |tee -a "${OutPutLog}"
    sed -i '/;\ NULL_/d' "${OutPutLog}"
    ## mod m3u8
    if [ -f "${ScriptDir}/${M3u8mod}" ]; then
      bash "${ScriptDir}/${M3u8mod}" "${OutPutLog}" "${OutPutM3u8}"
    fi
  done
done

# publish
if [ -f "${ScriptDir}/${Publish}" ]; then
  echo "publish ..."
  bash "${ScriptDir}/${Publish}" "${OutPutM3u8}"
fi
