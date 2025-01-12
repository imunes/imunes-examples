#!/bin/sh

. ../../common/procedures.sh

err=0

if isOSlinux; then
	ip link del rjvlan0 > /dev/null 2>&1

	ip link add name rjvlan0 type veth peer name rjvlan1
	ip link set rjvlan0 up
	ip link set rjvlan1 up
else
	ngctl msg rjvlanlink: shutdown > /dev/null 2>&1
	ngctl msg rjvlan0: shutdown > /dev/null 2>&1
	ngctl msg rjvlan1: shutdown > /dev/null 2>&1

	test0=`printf "mkpeer eiface ether ether \n show .ether" | ngctl -f - | head -n1 | awk '{print $2}'`
	ngctl name $test0: rjvlan0
	ifconfig $test0 name rjvlan0
	ifconfig rjvlan0 up
	test1=`printf "mkpeer eiface ether ether \n show .ether" | ngctl -f - | head -n1 | awk '{print $2}'`
	ngctl name $test1: rjvlan1
	ifconfig $test1 name rjvlan1
	ifconfig rjvlan1 up

	ngctl mkpeer rjvlan0: pipe ether upper
	ngctl name rjvlan0:ether rjvlanlink
	ngctl connect rjvlanlink: rjvlan1: lower ether
	ngctl msg rjvlanlink: setcfg {header_offset=14}
fi

eid=`imunes -b rj45vlan.imn | tail -1 | cut -d' ' -f4`
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

imunes -b -e $eid

eid=`imunes -b rj45vlan_directlink.imn | tail -1 | cut -d' ' -f4`
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

imunes -b -e $eid

if isOSlinux; then
	ip link del rjvlan0
else
	ngctl msg rjvlanlink: shutdown
	ngctl msg rjvlan0: shutdown
	ngctl msg rjvlan1: shutdown
fi

thereWereErrors $err
