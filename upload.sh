#!/bin/bash

# Max file size: 5M
# bash upload.sh <FileName|FolderName> <ThreadNum>
#       by MoeClub.org

# Config
DebugMode=0
ShowTask=0
ShowFileName=1

# Main
FileName=${1:-}
ThreadNum=${2:-10}
[ -n "$FileName" ] && [ -e "$FileName" ] || exit 1

PIPE=$(mktemp -u)
mkfifo $PIPE
exec 777<>$PIPE
trap "exec 777>&-;exec 777<&-;rm $PIPE;exit 0" 2
for((i=0; i<$ThreadNum; i=i+1)); do echo >&777; done

function Upload() {
  Name=`echo "$1" |sed 's/[[:space:]]//g'`;
  [ -n "${Name}" ] && [ -f "${Name}" ] || { echo >&777; return; }
  [ $ShowTask == 1 ] && echo "Upload Task: ${Name}";
  OUTPUT=`curl -sSL \
    -H "User-Agent: iAliexpress/6.22.1 (iPhone; iOS 12.1.2; Scale/2.00)" \
    -H "Referer: https://photobank.alibaba.com/photobank/uploader_dialog/index.htm" \
    -H "origin: https://photobank.alibaba.com" \
    -F "scene=aeMessageCenterV2ImageRule" \
    -F "name=_.jpg" \
    -F "file=@${Name}" \
    -X POST "https://kfupload.alibaba.com/mupload"`
  [ $DebugMode == 1 ] && echo "$OUTPUT";
  URL=`echo "$OUTPUT" |grep -o 'https://[^"]*'`;
  if [ -n "${URL}" ]; then
    if [ $ShowFileName == 1 ]; then
      echo "${Name}; ${URL}";
    else
      echo "${URL}";
    fi
  else
    echo "${Name}; NULL";
  fi
  echo >&777;
}

if [ -d "${FileName}" ]; then
  for item in `find "${FileName}" -type f ! -name ".*"`; do
    read -u777
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
