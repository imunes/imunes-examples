#!/bin/sh

. ../common/procedures.sh

err=0
legacy=""
if test -n "$LEGACY"; then
    legacy=" -l"
fi

eid=`imunes$legacy -b ipsec66.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

sleep 3
./start66.sh $eid
if [ $? -eq 0 ]; then
    netDump routerX@$eid eth0 ip6
    if [ $? -eq 0 ]; then
	ping6Check pc1@$eid bbbb::20 2
	if [ $? -eq 0 ]; then
	    sleep 2
	    esps=`readDump routerX@$eid eth0`
	    if [ $? -eq 0 ]; then
		echo "$esps"
		echo $esps | grep -q "ESP"
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
    echo "********** START66 ERROR **********"
    err=1
fi

imunes$legacy -b -e $eid

thereWereErrors $err
