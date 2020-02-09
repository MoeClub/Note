#!/bin/bash

# Usage: bash wget.sh <URL|FileName> <ThreadNum> <LoopNum>

FileName=${1:-wget.txt}
ThreadNum=${2:-10}
LoopNum=${3:-20}
UserAgent="Mozilla/5.0"

if [ -f "${FileName}" ]; then
	Mode=0
else
	Mode=1
fi

PIPE=$(mktemp -u)
mkfifo $PIPE
exec 777<>$PIPE
trap "exec 777>&-;exec 777<&-;rm $PIPE;exit 0" 2

for((i=0; i<$ThreadNum; i=i+1)); do
	echo >&777
done

function Task() {
	[ -n "$1" ] && wget --no-check-certificate --header="User-Agent: ${UserAgent}" --header="Referer: $1" "$1" >/dev/null 2>&1
	echo >&777
}

for((i=0; i<$LoopNum; i=i+1)); do
	if [ $Mode -eq 0 ]; then
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
