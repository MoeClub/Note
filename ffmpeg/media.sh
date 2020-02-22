#!/bin/bash

Media="$1"
Uploader="upload_yuque.sh"
M3u8mod="m3u8.sh"
Thread=2
MaxSize=20
BitRadio="1.35"

# Main
if [ -n "${Media}" ] && [ -f "${Media}" ]; then
  echo "media file: '${Media}'."
else
  echo "Not found '${Media}'."
  exit 1
fi

MediaName=`basename "${Media}" |cut -d'.' -f1`
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
VideoTime=`awk 'BEGIN{print ('${MaxSize}' * 1024 * 1024) / ('${BitRate}' * '${BitRadio}' / 8) }' |cut -d'.' -f1`
[ -n "$VideoTime" ] || exit 1
ffmpeg -i "${Media}" -threads ${Thread} -thread_type slice -vcodec copy -acodec aac -bsf:v h264_mp4toannexb -map 0 -f segment -segment_list ${OutPutM3u8} -segment_time ${VideoTime} "${MediaFolder}/output_%04d.ts"

## upload
if [ -f "${ScriptDir}/${Uploader}" ]; then
  bash "${ScriptDir}/${Uploader}" "${MediaFolder}" |tee -a "${OutPutLog}"
  ## mod m3u8
  if [ -f "${ScriptDir}/${M3u8mod}" ]; then
    bash "${ScriptDir}/${M3u8mod}" "${OutPutLog}" "${OutPutM3u8}"
  fi
fi
