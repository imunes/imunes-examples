#!/bin/sh

. ../../common/procedures.sh

if test `uname -s` == "Linux"; then
    echo "This example currently runs only on FreeBSD"
    thereWereErrors 1
    exit 0
fi

err=0

test0=`printf "mkpeer eiface ether ether \n show .ether" | ngctl -f - | head -n1 | awk '{print $2}'`
ngctl name $test0: test0
ifconfig $test0 name test0
ifconfig test0 up
test1=`printf "mkpeer eiface ether ether \n show .ether" | ngctl -f - | head -n1 | awk '{print $2}'`
ngctl name $test1: test1
ifconfig $test1 name test1
ifconfig test1 up

ngctl mkpeer test0: pipe ether upper
ngctl name test0:ether testlink
ngctl connect testlink: test1: lower ether
ngctl msg testlink: setcfg {header_offset=14}

eid=`imunes -b extvlan.imn | tail -1 | cut -d' ' -f4`
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

ngctl msg test0: shutdown
ngctl msg test1: shutdown
ngctl msg testlink: shutdown

thereWereErrors $err
