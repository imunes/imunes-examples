#!/bin/sh

. ../../common/procedures.sh

if isOSlinux; then
    echo "Test not supported on Linux."
    exit 0
fi

err=0
legacy=""
if test -n "$LEGACY"; then
    legacy=" -l"
fi

# execute ext topology
exteid=`imunes$legacy -b -e pgrj ext.imn | tail -1 | cut -d' ' -f4`
startCheck "$exteid"

eid=`imunes$legacy -b topo.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

if isOSlinux; then
    himage pc1@$exteid ip neigh add 10.0.0.21 lladdr 42:00:aa:00:00:01 dev eth0
    himage pc2@$exteid ip neigh add 10.0.0.21 lladdr 42:00:aa:00:00:01 dev eth0
else
    himage pc1@$exteid arp -s 10.0.0.21 42:00:aa:00:00:01
    himage pc2@$exteid arp -s 10.0.0.21 42:00:aa:00:00:01
fi

echo "Checking if link l0 exists:"
if isOSlinux; then
    himage -E $eid ip link show l0 2>&1
else
    himage -E $eid ngctl show l0: 2>&1
fi

if [ $? -eq 0 ]; then
    netDump pc1@$exteid eth0 icmp
    if [ $? -eq 0 ]; then
	sleep 3
	num=$(readDump pc1@$exteid eth0 | wc -l)
	if [ $? -eq 0 ]; then
	    num=$((num-3))
	    if [ $num -lt 4 ]; then
		echo "ERROR: captured only $num packets, should be 4"
		err=1
	    fi
	else
	    echo "ERROR: readDump failed"
	    err=1
	fi
    else
	echo "ERROR: netDump failed"
	err=1
    fi
else
    echo "ERROR: link l0 does not exist, but it should."
    err=1
fi

echo "Checking if link l1 does not exist:"
if isOSlinux; then
    himage -E $eid ip link show l1 2>&1
else
    himage -E $eid ngctl show l1: 2>&1
fi

if [ $? -ne 0 ]; then
    netDump pc2@$exteid eth0 icmp
    if [ $? -eq 0 ]; then
	sleep 3
	num=$(readDump pc2@$exteid eth0 | wc -l)
	if [ $? -eq 0 ]; then
	    num=$((num-3))
	    if [ $num -lt 4 ]; then
		echo "ERROR: captured only $num packets, should be 4"
		err=1
	    fi
	else
	    echo "ERROR: readDump failed"
	    err=1
	fi
    else
	echo "ERROR: netDump failed"
	err=1
    fi
else
    echo "ERROR: link l1 exists, but it should not."
    err=1
fi

imunes$legacy -b -e $eid

# terminate ext topology
imunes$legacy -b -e $exteid

thereWereErrors $err
