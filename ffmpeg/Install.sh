#!/bin/bash

# bash Install.sh

ItemURL="https://raw.githubusercontent.com/MoeClub/Note/master/ffmpeg/"
FileList=("upload.sh" "publish.sh" "media.sh" "m3u8.sh" "Player/Player.html" "Player/Player.py" "Player/static/css/video-js.min.css" "Player/static/js/video.min.js" "Player/static/js/videojs.hotkeys.min.js")

for Item in "${FileList[@]}"; do
  echo "Download ${Item} ..."
  echo "${Item}" |grep -q "/"
  [ $? -eq 0 ] && mkdir -p "$(dirname ${Item})"
  wget --no-check-certificate --no-cache -qO "${Item}" "${ItemURL}${Item}"
  chmod 755 "${Item}"
done

mkdir -p "Player/data"
chmod 755 "Player/data"
