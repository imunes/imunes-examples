#!/bin/sh

. ../common/procedures.sh

dns_servers="aRootServer bRootServer cRootServer \
             dnsCom dnsOrg dnsHr hr2 \
             dnsFer \
             dnsTel dnsZpm"
hosts="mm www pc zpmMail"
err=0

eid=`imunes -b NETWORK.imn | tail -1 | cut -d' ' -f4`
startCheck "$eid"

./start_dns $eid
sleep 20
if [ $? -ne 0 ]; then
    echo "********** START_DNS ERROR **********"
    err=1
else
    for h in $dns_servers $hosts; do 
	    dnsCheck $h@$eid zpmMail.zpm.fer.hr
	    if [ $? -eq 0 ]; then
		dnsCheck $h@$eid mm.tel.fer.hr
		if [ $? -ne 0 ]; then
		    err=1
		fi
	    else
		err=1
	    fi
    done
fi

himage www@$eid grep imunes /etc/passwd
if [ $? -eq 1 ]; then
    echo imunes | chroot /var/imunes/vroot pw useradd imunes -d /home/imunes -g wheel -k /usr/share/skel -s /usr/local/bin/bash -m -h 0 
fi

./start_mail $eid
if [ $? -ne 0 ]; then
    echo "********** START_MAIL ERROR **********"
    err=2
else
    sendMail www@$eid imunes@zpm.fer.hr
    if [ $? -ne 0 ]; then
	err=2
    else
        echo Wait 5 sec before reading e-mail...
	sleep 5
	getMail pc@$eid pop3://imunes:imunes@www.zpm.fer.hr
	if [ $? -ne 0 ]; then
	    err=2
	fi
    fi
fi

./start_http $eid
sleep 1
if [ $? -ne 0 ]; then
    echo "********** START_HTTP ERROR **********"
    err=3
else
    webCheck mm@$eid http://www.tel.fer.hr
    if [ $? -ne 0 ]; then
	err=3
    else
	webCheck mm@$eid http://www.zpm.fer.hr
	if [ $? -ne 0 ]; then
	    err=3
	fi
    fi
fi

imunes -b -e $eid

thereWereErrors $err
