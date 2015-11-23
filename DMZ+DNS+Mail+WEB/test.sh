#!/bin/sh

. ../common/procedures.sh

dns_servers="aRootServer bRootServer cRootServer \
             dnsCom dnsOrg dnsHr hr2 \
             dnsFer \
             dnsTel dnsZpm dnsMM"
hosts="mm www pc zpmMail"
err=0

eid=`imunes -b NETWORK.imn | awk '/Experiment/{print $4; exit}'`
startCheck "$eid"

echo "********"
echo "* Tested without firewall! "
echo "* (ipfw can affect other tests that are running in parallel) "
echo "********"
# ./start_fw

./start_dns $eid
if [ $? -ne 0 ]; then
    echo "********** START_DNS ERROR **********"
    err=1
    imunes -b -e $eid
    thereWereErrors $err
    exit $err
else
    echo Wait 30 sec ...
    sleep 30
    for h in $dns_servers $hosts; do 
	dnsCheck $h@$eid zpmMail.zpm.fer.hr
	if [ $? -eq 0 ]; then
	    dnsCheck $h@$eid mm.tel.fer.hr
	    if [ $? -eq 0 ]; then
	        dnsCheck $h@$eid www.mm.com
	        if [ $? -eq 0 ]; then
	            dnsCheck $h@$eid www.mm.com
	            if [ $? -ne 0 ]; then
		        err=1
                    fi
                else
		    err=1
                fi
            else
                err=1
	    fi
	else
	    err=1
	fi
    done
fi

./start_mail $eid
if [ $? -ne 0 ]; then
    echo "********** START_MAIL ERROR **********"
    err=2
else
    himage www@$eid grep imunes /etc/passwd > /dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo "User imunes should be created in virtual nodes."
        err=2
    fi
    sendMail www@$eid imunes@zpm.fer.hr
    if [ $? -ne 0 ]; then
	err=2
    else
        echo Wait 5 sec before reading e-mail...
	sleep 5
	getMail pc@$eid 30.0.0.4
	if [ $? -ne 0 ]; then
	    err=2
        else
            sendMail www@$eid imunes@mm.com
            if [ $? -ne 0 ]; then
	        err=2
            else
                echo Wait 5 sec before reading e-mail...
	        sleep 5
	        getMail wwwMM@$eid 15.16.17.25
	        if [ $? -ne 0 ]; then
	            err=2
                fi
            fi
	fi
    fi
fi

./start_http $eid
if [ $? -ne 0 ]; then
    echo "********** START_HTTP ERROR **********"
    err=3
else
    sleep 1
    webCheck mm@$eid http://www.tel.fer.hr
    if [ $? -ne 0 ]; then
	err=3
    else
	webCheck mm@$eid http://www.zpm.fer.hr
	if [ $? -ne 0 ]; then
	    err=3
        else
	    webCheck mm@$eid http://www.mm.com
	    if [ $? -ne 0 ]; then
	        err=3
            fi
	fi
    fi
fi

imunes -b -e $eid

thereWereErrors $err
