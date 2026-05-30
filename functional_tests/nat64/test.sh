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

netDump host@$eid eth0 icmp
if [ $? -eq 0 ]; then
	n=1
	pingStatus=1
	while [ $n -le 5 ] && [ $pingStatus -ne 0 ]; do
		echo "Ping test $n / 5 ..."
		pingCheck pc@$eid 120.0.0.10 2
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

if [ $err -eq 0 ]; then
	netDump pc@$eid eth0 icmp
	if [ $? -eq 0 ]; then
		n=1
		pingStatus=1
		while [ $n -le 5 ] && [ $pingStatus -ne 0 ]; do
			echo "Ping test $n / 5 ..."
			ping6Check mapped@$eid 2001::10.0.0.20 2
			pingStatus=$?
			n=`expr $n + 1`
		done
		if [ $pingStatus -eq 0 ]; then
			Wait 4
			readDump pc@$eid eth0
			err=$?
		else
			err=1
		fi
	else
		err=1
	fi
fi

if [ $err -eq 0 ]; then
	netDump mapped@$eid eth0 icmp6
	if [ $? -eq 0 ]; then
		n=1
		pingStatus=1
		while [ $n -le 20 ] && [ $pingStatus -ne 0 ]; do
			echo "Ping test $n / 20 ..."
			pingCheck pc@$eid 192.168.64.254 2
			pingStatus=$?
			n=`expr $n + 1`
		done
		if [ $pingStatus -eq 0 ]; then
			Wait 4
			readDump mapped@$eid eth0
			err=$?
		else
			err=1
		fi
	else
		err=1
	fi
fi

if [ $err -eq 0 ]; then
	netDump host@$eid eth0 icmp
	if [ $? -eq 0 ]; then
		n=1
		pingStatus=1
		while [ $n -le 5 ] && [ $pingStatus -ne 0 ]; do
			echo "Ping test $n / 5 ..."
			ping6Check mapped@$eid 2001::120.0.0.10 2
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
fi

imunes$legacy$debug -b -e $eid

if test "$DEBUG" = "1"; then
	mv /var/log/imunes/$eid.log .
fi

thereWereErrors $err
