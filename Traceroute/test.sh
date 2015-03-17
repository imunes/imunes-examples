#!/bin/sh

. ../common/procedures.sh

err=0

eid=`imunes -b traceroute.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

netDump pc1@$eid eth0
if [ $? -eq 0 ]; then
    sleep 3
    traceCheck pc1@$eid 10.0.8.10
    if [ $? -eq 0 ]; then
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
