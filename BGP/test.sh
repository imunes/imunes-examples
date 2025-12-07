#!/bin/sh

. ../common/procedures.sh

err=0
slow=1
legacy=""
if test "$LEGACY" = "1"; then
    legacy=" -l"
fi

debug=""
if test "$DEBUG" = "1"; then
    debug=" -d"
fi

if isOSlinux; then
    # Reverse-Path Filtering should be disabled
    default_rp_filter=$(sysctl net.ipv4.conf.default.rp_filter | awk '{print $3}')
    all_rp_filter=$(sysctl net.ipv4.conf.all.rp_filter | awk '{print $3}')

    if test $default_rp_filter -ne 0 -o $all_rp_filter -ne 0; then
        echo "Disabling Reverse-Path Filtering during the test."
        sysctl -w net.ipv4.conf.default.rp_filter=0
        sysctl -w net.ipv4.conf.all.rp_filter=0
    fi
fi

# BGP_custom-config.imn / BGP-Anycast_custom-config.imn
eid=`imunes$legacy$debug -b BGP-Anycast_custom-config.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

Wait 40
netDump DC2@$eid eth0 icmp
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
	readDump DC2@$eid eth0
	echo "########## Backbone1@$eid routes"
	himage -nt Backbone1@$eid vtysh << __END__
	show ip route
	exit
__END__
	if [ $slow -eq 1 ]; then
	    stopNode DC2@$eid 
	    if [ $? -eq 0 ]; then
		Wait 180

		echo ""
		echo "########## Backbone1@$eid routes after 180 seconds"
		himage -nt Backbone1@$eid vtysh << __END__ 
		show ip route
		exit
__END__

		netDump DC1@$eid eth0 icmp
		if [ $? -eq 0 ]; then
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
			readDump DC1@$eid eth0
		    else
			err=1
		    fi
		else
		    err=1
		fi

		startNode DC2@$eid
		if [ $? -eq 0 ]; then
		    Wait 3
                    n=1
                    pingStatus=1
					netDump DC2@$eid eth0 icmp
                    while [ $n -le 20 ] && [ $pingStatus -ne 0 ]; do
                        echo "Ping test2 $n / 20 ..."
                        pingCheck Client2@$eid 8.8.8.8 2
                        pingStatus=$?
                        n=`expr $n + 1`
                    done
                    if [ $pingStatus -eq 0 ]; then
			Wait 4
			readDump DC2@$eid eth0
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

if isOSlinux; then
    echo "Restoring Reverse-Path Filter settings."
    sysctl -w net.ipv4.conf.default.rp_filter=$default_rp_filter
    sysctl -w net.ipv4.conf.all.rp_filter=$all_rp_filter
fi

thereWereErrors $err
