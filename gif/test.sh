#!/bin/sh

. ../common/procedures.sh

if test `uname -s` == "Linux"; then
    echo "This example currently runs only on FreeBSD"
    thereWereErrors 1
    exit 0
fi

err=0

eid=`imunes -b gif.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

./start_gif.sh $eid
echo "Waiting for 20 seconds..."
sleep 20

netDump pc1@$eid eth0 icmp6
if [ $? -eq 0 ]; then
    n=1
    pingStatus=1
    while [ $n -le 20 ] && [ $pingStatus -ne 0 ]; do
        echo "Ping test $n / 20 ..."
        ping6Check pc1@$eid fc00:4::20 2
        pingStatus=$?
        n=`expr $n + 1`
    done
    if [ $pingStatus -eq 0 ]; then
	sleep 2
	readDump pc1@$eid eth0
	err=$?
    else
	err=1
    fi
else
    err=1
fi

imunes -b -e $eid

thereWereErrors $err
