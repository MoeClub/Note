#!/bin/bash

LogFile="${1:-log.txt}"
M3u8File="${2:-output.m3u8}"

if [ -n "${LogFile}" ] && [ -f "${LogFile}" ]; then
  echo "log file: '${LogFile}'."
else
  echo "Not found '${LogFile}'."
  exit 1
fi

if [ -n "${M3u8File}" ] && [ -f "${M3u8File}" ]; then
  echo "m3u8 file: '${M3u8File}'."
else
  echo "Not found '${M3u8File}'."
  exit 1
fi

while read line; do
  SrcName=`echo "$line" |cut -d';' -f1 |sed 's/^[[:space:]]*//' |sed 's/[[:space:]]*$//'`
  URL=`echo "$line" |cut -d';' -f2 |sed 's/^[[:space:]]*//' |sed 's/[[:space:]]*$//'`
  echo "$URL" |grep -q '^NULL'
  [ $? -eq 0 ] && countinue
  Name=`basename "$SrcName"`
  echo "$Name --> $URL"
  sed -i "s|$Name|$URL|" "${M3u8File}"
done < "${LogFile}";
