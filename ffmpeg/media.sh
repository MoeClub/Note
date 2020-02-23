#!/bin/bash

Media="$1"
Uploader="upload_yuque.sh"
M3u8mod="m3u8.sh"
Thread=2
MaxSize=20
BitRadio="1.35"
MaxCheck=10

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
echo "media bitrate: ${BitRate}"
MediaCode=`ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "${Media}" |sort |uniq`
if [ "$MediaCode" == "h264" ]; then
  VideoCode="copy"
else
  VideoCode="h264"
fi
if [ "$VideoCode" == "copy" ]; then
  VideoAddon="-bsf:v h264_mp4toannexb"
else
  if [ "$BitRate" -ge "2000000" ]; then
    VideoAddon="-b:v 2000k -maxrate 2250k -bufsize 2000k"
    BitRate=3000000
    echo "media bitrate(new): ${BitRate}"
  else
    VideoAddon=""
  fi
fi
VideoTime=`awk 'BEGIN{print ('${MaxSize}' * 1024 * 1024) / ('${BitRate}' * '${BitRadio}' / 8) }' |cut -d'.' -f1`
[ -n "$VideoTime" ] || exit 1
echo "media segment time: ${VideoTime}"
ffmpeg -v info -i "${Media}" -vcodec ${VideoCode} -acodec aac ${VideoAddon} -map 0:v:0 -map 0:a? -f segment -segment_list ${OutPutM3u8} -segment_time ${VideoTime} "${MediaFolder}/output_%04d.ts"
[ $? -eq 0 ] || exit 1

## upload
if [ -f "${ScriptDir}/${Uploader}" ]; then
  bash "${ScriptDir}/${Uploader}" "${MediaFolder}" |tee -a "${OutPutLog}"
  ## mod m3u8
  if [ -f "${ScriptDir}/${M3u8mod}" ]; then
    bash "${ScriptDir}/${M3u8mod}" "${OutPutLog}" "${OutPutM3u8}"
  fi
fi

# check
for((i=0; i<$MaxCheck; i++)); do
  BadCheck=`grep -v "^#\|^https\?://" "${OutPutM3u8}"`
  [ -n "$BadCheck" ] || break
  for Item in `echo "$BadCheck"`; do
    bash "${ScriptDir}/${Uploader}" "${Item}" |tee -a "${OutPutLog}"
    sed -i '/;\ NULL_/d' "${OutPutLog}"
    ## mod m3u8
    if [ -f "${ScriptDir}/${M3u8mod}" ]; then
      bash "${ScriptDir}/${M3u8mod}" "${OutPutLog}" "${OutPutM3u8}"
    fi
  done
done

