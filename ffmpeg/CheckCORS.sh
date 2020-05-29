#!/bin/bash

URL="${1:-https://cdn.nlark.com/yuque/0/2020/png/978548/1582464742099-7e2499fd-d2c1-47aa-a848-0c189a74bb77.png}"
SubDomainList=("cdn")
# length: ${#SubDomainList[@]}
# all: ${SubDomainList[@]}

CheckURL(){
  FullURL=`echo "$1" |sed 's/.*\([hHfF][tT][tT]*[pP][^:]*:\/\/\(\([^\.]*\)[^/]*\).*\).*/\1/'`
  [ -n "$FullURL" ] || return
  HostName=`echo "$FullURL" |sed 's/.*\([hHfF][tT][tT]*[pP][^:]*:\/\/\(\([^\.]*\)[^/]*\).*\).*/\2/'`
  OUTPUT=`curl -sSL -H "User-Agent: Mozilla/5.0" -I "$FullURL" |grep -i "^access-control-allow-origin" |cut -d":" -f2-`
  [ -n "$OUTPUT" ] || OUTPUT="None"
  echo "$HostName: $OUTPUT"
}

[ -n "$1" ] && Mode=0 || Mode=1

if [ "$Mode" == "0" ]; then
  CheckURL "$URL"
else
  for SubDomain in "${SubDomainList[@]}"; do 
    BaseURL=`echo "$URL" |sed 's/.*\([hHfF][tT][tT]*[pP][^:]*:\/\/\(\([^\.]*\)[^/]*\).*\).*/\1/'`
    HostName=`echo "$BaseURL" |sed 's/.*\([hHfF][tT][tT]*[pP][^:]*:\/\/\(\([^\.]*\)[^/]*\).*\).*/\2/'`
    NewHostName=`echo "$HostName" |sed "s/\([^\.]*\)/${SubDomain}/"`
    NewURL=`echo "$BaseURL" |sed "s/${HostName}/${NewHostName}/"`;
    CheckURL "$NewURL"
  done
fi
