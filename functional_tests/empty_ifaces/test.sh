#!/bin/sh

. ../../common/procedures.sh

err=0
legacy=""
if test -n "$LEGACY"; then
    legacy=" -l"
fi

eid=`imunes$legacy -b empty.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

netDump pc1@$eid eth0 icmp
if [ $? -eq 0 ]; then
    sleep 4
    pingCheck pc1@$eid 20.0.0.1 2
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

imunes$legacy -b -e $eid

thereWereErrors $err
