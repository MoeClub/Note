#!/bin/bash

File="${1:-}"
Token="MoeClub"
URL="http://127.0.0.1:5866/Player"

[ -n "$File" ] && [ -f "$File" ] || exit 1
RESP=`curl -sSL -F "file=@${File}" -X POST "${URL}/${Token}"`
echo "${File} --> ${RESP}"


