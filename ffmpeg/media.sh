#!/bin/bash

Media="$1"
Uploader="upload_yuque.sh"
Thread=2

# Main
if [ -n "${Media}" ] && [ -f "${Media}" ]; then
  echo "media file: '${Media}'."
else
  echo "Not found '${Media}'."
  exit 1
fi

MediaName=`basename "${Media}" |cut -d'.' -f1`
OutPutM3u8="${MediaName}.m3u8"
OutPutLog="${MediaName}.log"
MediaFloder="${MediaName}.output"


## m3u8
ffmpeg -i ${Media} -threads ${Thread} -thread_type slice -vcodec copy -acodec aac -bsf:v h264_mp4toannexb -map 0 -f segment -segment_list output.m3u8 -segment_time 10 ${MediaFloder}/output_%03d.ts

## upload
if [ -f "${Uploader}" ]; then
  bash "${Uploader}" "${MediaFloder}" |tee -a "${OutPutLog}"
  ## mod m3u8
  if [ -f "m3u8.sh" ]; then
    bash "m3u8.sh" "${OutPutLog}" "${OutPutM3u8}"
  fi
fi
