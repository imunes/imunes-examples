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

eid=`imunes$legacy$debug -b services.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

# wait for the services to start
sleep 5

# ftp
himage FTP@$eid netstat -an | grep LISTEN | grep -q "21"
if [ $? -ne 0 ]; then
    echo "FTP error"
    err=1
fi

# ssh
himage SSH@$eid netstat -an | grep LISTEN | grep -q "22"
if [ $? -ne 0 ]; then
    echo "SSH error"
    err=1
fi

# telnet
himage TELNET@$eid netstat -an | grep LISTEN | grep -q "23"
if [ $? -ne 0 ]; then
    echo "TELNET error"
    err=1
fi

imunes$legacy$debug -b -e $eid

if test "$DEBUG" = "1"; then
	mv /var/log/imunes/$eid.log .
fi

# tcpdump
# testing after termination because that's when the file is saved in /tmp/$eid
file /tmp/$eid/TCPDUMP_n3_eth0.pcap | grep -q "capture file"
if [ $? -ne 0 ]; then
    echo "TCPDUMP error"
    err=1
fi

thereWereErrors $err
