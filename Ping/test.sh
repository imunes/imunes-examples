#!/bin/sh

. ../common/procedures.sh

err=0

eid=`imunes -b ping.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

netDump pc1@$eid eth0 icmp
if [ $? -eq 0 ]; then
    sleep 8
    pingCheck pc1@$eid 10.0.8.10 2
    if [ $? -eq 0 ]; then
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
