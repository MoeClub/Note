#!/bin/bash

yuque_ctoken="${1:-}"
yuque_session="${2:-}"

[ -n "$yuque_ctoken" ] && [ -n "$yuque_session" ] || exit 1
ItemURL="https://raw.githubusercontent.com/MoeClub/Note/master/ffmpeg/"
FileList=("upload_yuque.sh" "publish.sh" "media.sh" "m3u8.sh" "Player/Player.html" "Player/Player.py" "Player/static/css/video-js.min.css" "Player/static/js/video.min.js" "Player/static/js/videojs.hotkeys.min.js")

for Item in "${FileList[@]}"; do
   echo "Download ${Item} ..."
   wget --no-check-certificate -qPO "${Item}" "${ItemURL}${Item}"
   chmod 755 "${Item}"
done

sed -i "s/^ctoken=.*/ctoken=\"$yuque_ctoken\"" upload_yuque.sh
sed -i "s/^session=.*/session=\"$yuque_session\"" upload_yuque.sh
cp -rf upload_yuque.sh upload.sh
chmod 755 upload.sh
mkdir -p "Player/data"
chmod 755 "Player/data"
