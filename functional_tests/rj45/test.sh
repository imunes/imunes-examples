#!/bin/sh

. ../../common/procedures.sh

err=0
legacy=""
if test -n "$LEGACY"; then
    legacy=" -l"
fi

if isOSlinux; then
	ip link del rj450 > /dev/null 2>&1

	ip link add name rj450 type veth peer name rj451
	ip link set rj450 up
	ip link set rj451 up
else
	ngctl msg rjlink: shutdown > /dev/null 2>&1
	ngctl msg rj450: shutdown > /dev/null 2>&1
	ngctl msg rj451: shutdown > /dev/null 2>&1

	test0=`printf "mkpeer eiface ether ether \n show .ether" | ngctl -f - | head -n1 | awk '{print $2}'`
	ngctl name $test0: rj450
	ifconfig $test0 name rj450
	ifconfig rj450 up
	test1=`printf "mkpeer eiface ether ether \n show .ether" | ngctl -f - | head -n1 | awk '{print $2}'`
	ngctl name $test1: rj451
	ifconfig $test1 name rj451
	ifconfig rj451 up

	ngctl mkpeer rj450: pipe ether upper
	ngctl name rj450:ether rjlink
	ngctl connect rjlink: rj451: lower ether
	ngctl msg rjlink: setcfg {header_offset=14}
fi

eid=`imunes$legacy -b rj45.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

netDump pc1@$eid eth0 icmp
if [ $? -eq 0 ]; then
    sleep 4
    pingCheck pc1@$eid 10.0.0.21 2
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

eid=`imunes$legacy -b rj45_directlink.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

netDump pc1@$eid eth0 icmp
if [ $? -eq 0 ]; then
    sleep 4
    pingCheck pc1@$eid 10.0.0.21 2
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

if isOSlinux; then
	ip link del rj450
else
	ngctl msg rjlink: shutdown
	ngctl msg rj450: shutdown
	ngctl msg rj451: shutdown
fi

thereWereErrors $err
