#!/bin/bash

# bash upload_yuque.sh <FileName|FolderName> <ThreadNum> |tee -a "log.txt"
#           by MoeClub.org

# User Cookies
ctoken=""
session=""


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
  OUTPUT=`curl -sSL --connect-timeout 5 --retry-delay 3 --retry 3 \
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:68.0) Gecko/20100101 Firefox/68.0" \
    -H "Referer: https://www.yuque.com/yuque/topics/new" \
    -H "Cookie: ctoken=${ctoken}; _yuque_session=${session}" \
    -F "file=@${Name};filename=_.png;type=image/png" \
    -X POST "https://www.yuque.com/api/upload/attach?ctoken=${ctoken}"`
  [ $DebugMode == 1 ] && echo "$OUTPUT";
  URL=`echo "$OUTPUT" |grep -o '"url":"[^"]*"' |grep -o 'https://[^"]*'`;
  if [ -n "${URL}" ]; then
    if [ $ShowFileName == 1 ]; then
      echo "${Name}; ${URL}";
    else
      echo "${URL}";
    fi
  else
    StatusCode=`echo "$OUTPUT" |cut -d'"' -f4 |sed 's/[[:space:]]/-/g'`
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
