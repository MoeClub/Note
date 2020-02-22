#!/bin/bash

# Max file size: 5M
# bash upload.sh <FileName|FolderName> <ThreadNum> |tee -a "log.txt"
#           by MoeClub.org

# Config
DebugMode=0
ShowTask=0
ShowFileName=1

# Main
FileName=${1:-}
ThreadNum=${2:-10}
command -v curl >>/dev/null 2>&1
[ $? -eq 0 ] || exit 1
[ -n "$FileName" ] && [ -e "$FileName" ] || exit 1

PIPE=$(mktemp -u)
mkfifo $PIPE
exec 77<>$PIPE
trap "exec 77>&-;exec 77<&-;rm $PIPE;exit 0" 2
for((i=0; i<$ThreadNum; i=i+1)); do echo >&77; done

function Upload() {
  Name=`echo "$1" |sed 's/[[:space:]]//g'`;
  [ -n "${Name}" ] && [ -f "${Name}" ] || { echo >&77; return; }
  [ $ShowTask == 1 ] && echo "Upload Task: ${Name}";
  OUTPUT=`curl -sSL \
    -H "User-Agent: iAliexpress/6.22.1 (iPhone; iOS 12.1.2; Scale/2.00)" \
    -H "Referer: https://photobank.alibaba.com/photobank/uploader_dialog/index.htm" \
    -H "origin: https://photobank.alibaba.com" \
    -F "scene=aeMessageCenterV2ImageRule" \
    -F "name=_.jpg" \
    -F "file=@${Name};filename=_.jpg;type=image/jpeg" \
    -X POST "https://kfupload.alibaba.com/mupload"`
  [ $DebugMode == 1 ] && echo "$OUTPUT";
  URL=`echo "$OUTPUT" |grep -io 'https://[^"]*'`;
  if [ -n "${URL}" ]; then
    if [ $ShowFileName == 1 ]; then
      echo "${Name}; ${URL}";
    else
      echo "${URL}";
    fi
  else
    StatusCode=`echo "$OUTPUT" |grep -io '"code":"[0-9]*"' |grep -o '[0-9]\+'`
    echo "${Name}; NULL_${StatusCode}";
  fi
  echo >&77;
}

if [ -d "${FileName}" ]; then
  for item in `find "${FileName}" -type f ! -name ".*"`; do
    read -u77
    Upload "${item}" &
  done
elif [ -f "${FileName}" ]; then
  # ShowFileName=0
  Upload "${FileName}" &
else
  exit 1
fi

wait
exit 0
