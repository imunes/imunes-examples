#!/bin/sh

. ../common/procedures.sh

err=0

eid=`imunes -b traceroute.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

netDump pc1@$eid eth0
if [ $? -eq 0 ]; then
    n=1
    traceStat=1
    while [ $n -le 20 ] && [ $traceStat -ne 0 ]; do
        echo "Traceroute test $n / 20 ..."
        traceCheck pc1@$eid 10.0.8.10
        traceStat=$?
        n=`expr $n + 1`
    done
    if [ $traceStat -eq 0 ]; then
	traceCheck server@$eid 10.0.0.21
	if [ $? -eq 0 ]; then
	    sleep 3
	    readDump pc1@$eid eth0
	    err=$?
	else
	    err=1
	fi
    else
	err=1
    fi
else
    err=1
fi

imunes -b -e $eid

thereWereErrors $err
