#!/bin/sh

. ../common/procedures.sh

err=0
slow=1

# BGP_custom-config.imn
eid=`imunes -b BGP-Anycast.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

Wait 40
netDump DC1@$eid eth1
if [ $? -eq 0 ]; then
    n=1
    pingStatus=1
    while [ $n -le 20 ] && [ $pingStatus -ne 0 ]; do
        echo "Ping test $n / 20 ..."
        pingCheck Client2@$eid 8.8.8.8 2
        pingStatus=$?
        n=`expr $n + 1`
    done
    if [ $pingStatus -eq 0 ]; then
	echo "########## Backbone1@$eid routes"
	himage -nt Backbone1@$eid vtysh << __END__
	show ip route
	exit
__END__
	if [ $slow -eq 1 ]; then
	    stopNode DC2@$eid 
	    if [ $? -eq 0 ]; then
		Wait 20

		echo ""
		echo "########## Backbone1@$eid routes after 45 seconds"
		himage -nt Backbone1@$eid vtysh << __END__ 
		show ip route
		exit
__END__

		startNode DC2@$eid
		if [ $? -eq 0 ]; then
		    Wait 30
                    n=1
                    pingStatus=1
                    while [ $n -le 20 ] && [ $pingStatus -ne 0 ]; do
                        echo "Ping test2 $n / 20 ..."
                        pingCheck Client2@$eid 8.8.8.8 2
                        pingStatus=$?
                        n=`expr $n + 1`
                    done
                    if [ $pingStatus -eq 0 ]; then
			Wait 4
			readDump DC1@$eid eth1
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

readDump DC1@$eid eth1
imunes -b -e $eid

thereWereErrors $err
