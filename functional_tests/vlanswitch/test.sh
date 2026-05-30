#!/bin/sh

. ../../common/procedures.sh

err=0
legacy=""
if test "$LEGACY" = "1"; then
	legacy=" -l"
fi

debug=""
if test "$DEBUG" = "1"; then
	debug=" -dd DEBUG.log"
fi

eid=`imunes$legacy$debug -b topo.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

netDump host@$eid eth0 vlan 4 and icmp
if [ $? -eq 0 ]; then
	n=1
	pingStatus=1
	while [ $n -le 5 ] && [ $pingStatus -ne 0 ]; do
		echo "Ping test $n / 5 ..."
		pingCheck pc-4@$eid 10.0.0.10 2
		pingStatus=$?
		n=`expr $n + 1`
	done
	if [ $pingStatus -eq 0 ]; then
		Wait 4
		readDump host@$eid eth0
		err=$?
	else
		err=1
	fi
else
	err=1
fi

netDump host@$eid eth0 vlan 6 and icmp6
if [ $? -eq 0 ]; then
	n=1
	pingStatus=1
	while [ $n -le 5 ] && [ $pingStatus -ne 0 ]; do
		echo "Ping test $n / 5 ..."
		pingCheck pc-6@$eid fc00::10 2
		pingStatus=$?
		n=`expr $n + 1`
	done
	if [ $pingStatus -eq 0 ]; then
		Wait 4
		readDump host@$eid eth0
		err=$?
	else
		err=1
	fi
else
	err=1
fi

imunes$legacy$debug -b -e $eid

if test "$DEBUG" = "1"; then
	mv /var/log/imunes/$eid.log .
fi

thereWereErrors $err
