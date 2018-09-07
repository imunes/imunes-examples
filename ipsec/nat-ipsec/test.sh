#!/bin/sh

. ../../common/procedures.sh
err=0

eid=`imunes -b nat-ipsec64.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

if isOSlinux; then
    himage nat@$eid iptables-restore < nat.rules.linux
else
    ./start_nat.sh $eid > /dev/null
fi

if [ $? -eq 0 ]; then
    sleep 4
    netDump nat@$eid eth1
    if [ $? -eq 0 ]; then
	pingCheck moon@$eid 10.0.1.2 1
	if [ $? -eq 0 ]; then
	    sleep 2
	    pings=`readDump nat@$eid eth1`
	    if [ $? -eq 0 ]; then
		echo "$pings"
		pings=`echo "$pings" | grep "echo request"`
		natsrc=`echo "$pings" | cut -f3 -d' '`
		natdst=`echo "$pings" | cut -f5 -d' '`

		if [ "$natsrc" = "10.0.3.2" ]; then
		    ./start_ipsec.sh $eid
		    if [ $? -eq 0 ]; then
			sleep 2
			netDump nat@$eid eth1 ip
			if [ $? -eq 0 ]; then
			    ping6Check pc1@$eid bbbb::20 2
			    if [ $? -eq 0 ]; then
				sleep 2
				esps=`readDump nat@$eid eth1`
				if [ $? -eq 0 ]; then
				    echo "$esps"
				    echo "$esps" | grep -q "ESP"
				    if [ $? -ne 0 ]; then
					echo ""
					echo "********* NO ESP ERROR ***********"
					err=1
				    fi
				else
				    echo "$esps"
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
			echo "********** START_IPSEC ERROR **********"
			err=1
		    fi
		else
		    if [ "$natsrc" = "10.0.0.1" ]; then
			echo ""
			echo "********** NAT ERROR **********"
			echo "********** IS NAT TURNED ON? **********"
		    else
			echo ""
			echo "********** CONNECTION ERROR **********"
		    fi
		    err=1
		fi
	    else
		echo "$pings"
		err=1
	    fi
	else
	    err=1
	fi
    fi
else
    echo "********* START_NAT ERROR ***********"
    err=1
fi

imunes -b -e $eid

thereWereErrors $err
