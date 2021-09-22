#!/bin/bash

Min=65
Max=95
Num=0

CORES=$(cat /proc/cpuinfo| grep -i "physical id"| sort| uniq| wc -l)
[ -n "$CORES" ] || CORES=1

function RAND() {
  min=$1
  max=$(($2-$min+1))
  num=`cat /dev/urandom |head -n10 |cksum |grep -o '[0-9]*' |head -n1`
  echo $(($num%$max+$min))
}

for((i=0;i<$CORES;i++)) do Num=$(($Num+$(RAND $Min $Max))); done

echo $Num
