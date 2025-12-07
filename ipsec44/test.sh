#!/bin/sh

. ../common/procedures.sh

err=0
legacy=""
if test "$LEGACY" = "1"; then
    legacy=" -l"
fi

debug=""
if test "$DEBUG" = "1"; then
    debug=" -d"
fi

eid=`imunes$legacy$debug -b ipsec44.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

sleep 3
./start44.sh $eid
if [ $? -eq 0 ]; then
    netDump routerX@$eid eth0 ip
    if [ $? -eq 0 ]; then
	pingCheck pc1@$eid 10.0.1.20 2
	if [ $? -eq 0 ]; then
	    sleep 2
	    esps=`readDump routerX@$eid eth0`
	    if [ $? -eq 0 ]; then
		echo "$esps"
		echo $esps | grep -qw "ESP"
		if [ $? -ne 0 ]; then
		    echo ""
		    echo "********* NO ESP ERROR ***********"
		    err=1
		fi
	    else
		echo $esps
		err=1
	    fi
	else
	    err=1
	fi
    else
	err=1
    fi
else
    echo ""
    echo "********** START44 ERROR **********"
    err=1
fi

imunes$legacy$debug -b -e $eid

if test "$DEBUG" = "1"; then
	mv /var/log/imunes/$eid.log .
fi

thereWereErrors $err
