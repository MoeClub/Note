#!/bin/bash

Media="$1"
Uploader="upload_yuque.sh"
M3u8mod="m3u8.sh"
Thread=2

# Main
if [ -n "${Media}" ] && [ -f "${Media}" ]; then
  echo "media file: '${Media}'."
else
  echo "Not found '${Media}'."
  exit 1
fi

MediaName=`basename "${Media}" |cut -d'.' -f1`
ScriptDir=`dirname $0`
OutPutM3u8="${MediaName}.m3u8"
OutPutLog="${MediaName}.log"
MediaFloder="${MediaName}.output"

# cache
rm -rf "${OutPutLog}"
rm -rf "${MediaFloder}"
mkdir -p "${MediaFloder}"

## m3u8
cd "${MediaFloder}"
ffmpeg -i ../${Media} -threads ${Thread} -thread_type slice -vcodec copy -acodec aac -bsf:v h264_mp4toannexb -map 0 -f segment -segment_list ../${OutPutM3u8} -segment_time 20 output_%04d.ts

## upload
cd ..
if [ -f "${ScriptDir}/${Uploader}" ]; then
  bash "${ScriptDir}/${Uploader}" "${MediaFloder}" |tee -a "${OutPutLog}"
  ## mod m3u8
  if [ -f "${ScriptDir}/${M3u8mod}" ]; then
    bash "${ScriptDir}/${M3u8mod}" "${OutPutLog}" "${OutPutM3u8}"
  fi
fi
