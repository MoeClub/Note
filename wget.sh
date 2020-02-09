#!/bin/bash

# Usage: bash wget.sh <URL/FileName> <ThreadNum> <LoopNum> <HOST|Address>


FileName=${1:-wget.txt}
ThreadNum=${2:-10}
LoopNum=${3:-20}
ServerHost="$4"


UserAgent="Mozilla/5.0"

FileMode=0
HostMode=0

if [ -f "${FileName}" ]; then
	FileMode=1
fi

echo "${ServerHost}" |grep -q "|"
if [ $? -eq 0 ]; then
	ServerName=`echo "${ServerHost}" |cut -d'|' -f1 |sed 's/[[:space:]]//g'`
	ServerAddr=`echo "${ServerHost}" |cut -d'|' -f2 |sed 's/[[:space:]]//g'`
	[ -n "$ServerName" ] && [ -n "$ServerAddr" ] && HostMode=1	
fi

PIPE=$(mktemp -u)
mkfifo $PIPE
exec 777<>$PIPE
trap "exec 777>&-;exec 777<&-;rm $PIPE;exit 0" 2

for((i=0; i<$ThreadNum; i=i+1)); do
	echo >&777
done

function Task() {
	if [ -n "$1" ]; then
		if [ $HostMode -eq 0 ]; then
	 		wget --no-check-certificate --header="User-Agent: ${UserAgent}" --header="Referer: $1" "$1" >/dev/null 2>&1
		else
			_URL=`echo "$1" |sed "s/$ServerName/$ServerAddr/"`
			wget --no-check-certificate --header="User-Agent: ${UserAgent}" --header="Referer: $1" --header="Host: $ServerName" "$_URL" >/dev/null 2>&1
		fi
	fi
	echo >&777
}

for((i=0; i<$LoopNum; i=i+1)); do
	if [ $FileMode -eq 1 ]; then
  	for line in `cat ${FileName}`; do
			read -u777
			_LINE=`echo -ne "$line" |sed 's/\r//g' |sed 's/\n//g'`
			echo "URL: $_LINE"
			Task "$_LINE" &
  	done
  else
  	read -u777
  	_LINE=`echo -ne "${FileName}" |sed 's/\r//g' |sed 's/\n//g'`
		echo "URL: $_LINE"
		Task "$_LINE" &
  fi
done

exit 0
