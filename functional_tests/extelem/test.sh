#!/bin/sh

. ../../common/procedures.sh

err=0
legacy=""
if test "$LEGACY" = "1"; then
    legacy=" -l"
fi

debug=""
if test "$DEBUG" = "1"; then
    debug=" -d"
fi

if isOSlinux; then
	ip link del extelem0 > /dev/null 2>&1

	ip link add name extelem0 type veth peer name extelem1
	ip link set extelem0 up
	ip link set extelem1 up
else
	ngctl msg extlink: shutdown > /dev/null 2>&1
	ngctl msg extelem0: shutdown > /dev/null 2>&1
	ngctl msg extelem1: shutdown > /dev/null 2>&1

	test0=`printf "mkpeer eiface ether ether \n show .ether" | ngctl -f - | head -n1 | awk '{print $2}'`
	ngctl name $test0: extelem0
	ifconfig $test0 name extelem0
	ifconfig extelem0 up
	test1=`printf "mkpeer eiface ether ether \n show .ether" | ngctl -f - | head -n1 | awk '{print $2}'`
	ngctl name $test1: extelem1
	ifconfig $test1 name extelem1
	ifconfig extelem1 up

	ngctl mkpeer extelem0: pipe ether upper
	ngctl name extelem0:ether extlink
	ngctl connect extlink: extelem1: lower ether
	ngctl msg extlink: setcfg {header_offset=14}
fi

eid=`imunes$legacy$debug -b extelem.imn | awk '/Experiment/{print $4; exit}'`
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

imunes$legacy$debug -b -e $eid

if test "$DEBUG" = "1"; then
	mv /var/log/imunes/$eid.log .
fi

eid=`imunes$legacy$debug -b extelem_directlink.imn | awk '/Experiment/{print $4; exit}'`
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

imunes$legacy$debug -b -e $eid

if test "$DEBUG" = "1"; then
	mv /var/log/imunes/$eid.log .
fi

if isOSlinux; then
	ip link del extelem0
else
	ngctl msg extlink: shutdown
	ngctl msg extelem0: shutdown
	ngctl msg extelem1: shutdown
fi

thereWereErrors $err
