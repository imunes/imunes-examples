#!/bin/sh

. ../common/procedures.sh

pcs="FIX PC1 PC2"
err=0
legacy=""
if test -n "$LEGACY"; then
    legacy=" -l"
fi

eid=`imunes$legacy -b DHCP.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

./start_dhcp $eid
if [ $? -ne 0 ]; then
    echo "********** START_DHCP ERROR **********"
    pcs=""
    err=1
fi

for pc in $pcs; do
    pingCheck $pc@$eid 10.0.2.2
    err=$?
    if [ $err -ne 0 ]; then
        break
    fi

    ip_addr=`getNodeIP $pc@$eid eth0`
    echo $ip_addr | grep -q "10.0.0."
    if [ $? -ne 0 ]; then
        echo "********** IFCONFIG ERROR **********"
        err=1
        break
    fi
done

if [ $err -eq 0 ]; then
    netDump PC3@$eid eth0 'port 67 and not arp or port 68 and not arp'
    if [ $? -eq 0 ]; then
        sleep 2
        himage PC3@$eid dhclient eth0
        if [ $? -eq 0 ]; then
            sleep 2
            readDump PC3@$eid eth0
            err=$?
        else
            echo "********** DHCLIENT ERROR **********"
            err=1
        fi
    else
        err=1
    fi
fi

imunes$legacy -b -e $eid

thereWereErrors $err

