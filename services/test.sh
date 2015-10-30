#!/bin/sh

. ../common/procedures.sh

err=0

eid=`imunes -b services.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

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

imunes -b -e $eid

# tcpdump
# testing after termination because that's when the file is saved in /tmp/$eid
file /tmp/$eid/TCPDUMP_n3_eth0.pcap | grep -q "tcpdump capture file"
if [ $? -ne 0 ]; then
    echo "TCPDUMP error"
    err=1
fi

thereWereErrors $err
