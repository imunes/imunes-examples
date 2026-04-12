#!/bin/sh

. ../common/procedures.sh

err=0
slow=0
legacy=""
if test "$LEGACY" = "1"; then
    legacy=" -l"
fi

debug=""
if test "$DEBUG" = "1"; then
    debug=" -dd DEBUG.log"
fi

eid=`imunes$legacy$debug -b RIP1.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

Wait 10
netDump router2@$eid eth2
if [ $? -eq 0 ]; then
    pingCheck pc@$eid 10.0.4.10
    if [ $? -eq 0 ]; then
	echo "########## router2@$eid routes"
	himage -nt router2@$eid vtysh << __END__
	show ip rip
	show ipv6 ripng
	exit
__END__
	Wait 30
	n=1
	pingStatus=1
	while [ $n -le 20 ] && [ $pingStatus -ne 0 ]; do
		echo "Ping test $n / 20 ..."
		ping6Check pc@$eid fc00:1::10
		pingStatus=$?
		n=`expr $n + 1`
	done
	if [ $pingStatus -eq 0 ]; then
		Wait 4
		echo ""
		readDump router2@$eid eth2
		if [ $? -ne 0 ]; then
		    err=1
		fi
	else
	    err=1
	fi

	if [ $slow -eq 1 ]; then
	    stopNode router7@$eid 
	    if [ $? -eq 0 ]; then
		Wait 190

		echo ""
		echo "########## router2@$eid routes after 3 minutes"
		himage -nt router2@$eid vtysh << __END__ 
		show ip rip
		show ipv6 ripng
		exit
__END__

		startNode router7@$eid
		if [ $? -eq 0 ]; then
		    Wait 10
		    pingCheck pc@$eid 10.0.4.10
		    if [ $? -eq 0 ]; then
			Wait 4
			readDump router2@$eid eth2
		    else
			err=1
		    fi
		    ping6Check pc@$eid fc00:1::10
		    if [ $? -eq 0 ]; then
			Wait 4
			readDump router2@$eid eth2
		    else
			err=1
		    fi
		else
		    err=1
		fi
	    else
		err=1
	    fi
	fi
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
