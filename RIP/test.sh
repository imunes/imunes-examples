#!/bin/sh

. ../common/procedures.sh

err=0
slow=0

eid=`imunes -b RIP1.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

sleep 10
netDump router2@$eid eth2
if [ $? -eq 0 ]; then
    pingCheck pc@$eid 10.0.4.10
    if [ $? -eq 0 ]; then
	echo "########## router2@$eid routes"
	himage router2@$eid vtysh << __END__
	show ip rip
	show ipv6 ripng
	exit
__END__
	sleep 2
	if [ $? -eq 0 ]; then
	    ping6Check pc@$eid fc00:1::10
	    if [ $? -eq 0 ]; then
		sleep 2
		echo ""
		readDump router2@$eid eth2
		if [ $? -ne 0 ]; then
		    err=1
		fi
	    else
		err=1
	    fi
	else
	    err=1
	fi

	if [ $slow -eq 1 ]; then
	    stopNode router7@$eid 
	    if [ $? -eq 0 ]; then
		sleep 190

		echo ""
		echo "########## router2@$eid routes after 3 minutes"
		himage router2@$eid vtysh << __END__ 
		show ip rip
		show ipv6 ripng
		exit
__END__

		startNode router7@$eid
		if [ $? -eq 0 ]; then
		    sleep 10
		    pingCheck pc@$eid 10.0.4.10
		    if [ $? -eq 0 ]; then
			sleep 4
			readDump router2@$eid eth2
		    else
			err=1
		    fi
		    ping6Check pc@$eid fc00:1::10
		    if [ $? -eq 0 ]; then
			sleep 4
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

imunes -b -e $eid

thereWereErrors $err
