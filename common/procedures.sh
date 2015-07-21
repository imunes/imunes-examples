#!/bin/sh

# Usage: thereWereErrors status
thereWereErrors () {
    if [ $1 -ne 0 ]; then
	echo ""
	echo "There were errors."
    fi
}

# Usage: ping6Check source_node dest_address [count]
ping6Check () {
    echo ""
    echo "########## $1 pinging $2"
    if [ "$3" == "" ]; then
	himage $1 ping6 -n -c1 $2
	ert=$?
    else
	himage $1 ping6 -n -c $3 $2
	ert=$?
    fi

    if [ $ert -ne 0 ]; then
	echo ""
	echo "********** PING6 ERROR **********"
	return $ert
    else
	return 0
    fi
}

# Usage: pingCheck source_node dest_address [count]
pingCheck () {
    echo ""
    echo "########## $1 pinging $2"
    if [ "$3" == "" ]; then
	himage $1 ping -W 2 -c1 $2
	ert=$?
    else
	himage $1 ping -W 2 -c $3 $2
	ert=$?
    fi

    if [ $ert -ne 0 ]; then
	echo ""
	echo "********** PING ERROR **********"
	return $ert
    else
	return 0
    fi
}

# Usage: getNodeIP node interface
getNodeIP () {
    ip_addr=`himage $1 ifconfig $2 | awk '/inet /{print $2}'`

    if [ "$ip_addr" == "" ]; then
	echo ""
	echo "********** IFCONFIG ERROR **********"
	return 1
    else
	echo $ip_addr
	return 0
    fi
}

# Usage netDump: netDump node interface [additional arguments]
netDump () {
    echo ""
    echo "########## Dumping tcpdump from $1 on $2"
    i=1
    args=""
    for arg in $*; do
	if [ $i -gt 2 ]; then
	    args="$args $arg"
	fi
	i=$(($i+1))
    done
    if test `uname -s` == "Linux"; then
        himage -b $1 sh -c "tcpdump -w /root/tcplog_$2 -ni $2 $args 2> tcplog_err_$2 &"
    else
        himage $1 sh -c "tcpdump -w /root/tcplog_$2 -ni $2 $args 2> tcplog_err_$2 &"
    fi
    sleep 1
    himage $1 cat tcplog_err_$2 | grep -q "error\|failed"
    if [ $? -eq 0 ]; then
	himage $1 cat tcplog_err_$2 2> /dev/null
	echo ""
	echo "********** TCPDUMP ERROR **********"
	return 1
    fi
    return 0
}

# Usage: startCheck experiment_id
startCheck () {
    if [ "$1" == "" ]; then
	echo ""
	echo "********** START ERROR **********"
	thereWereErrors 1
	exit 1
    fi
}

# Usage: readDump node interface
readDump () {
    echo ""
    echo "########## Reading tcpdump from $1 $2"
    if [ "`pgrep tcpdump`" != "" ]; then
	himage $1 pkill -f "tcpdump.*$2"
    fi
    himage $1 tcpdump -nr /root/tcplog_$2
    if [ $? -ne 0 ]; then
	echo ""
	echo "********* READDUMP ERROR ***********"
	return 1
    fi
    return 0
}

# Usage: traceCheck node destination
traceCheck () {
    echo ""
    echo "########## Traceroute check $1 $2"
    strVal=`himage $1 traceroute $2 | grep -v traceroute | grep "$2"`
    if [ "$strVal" == "" ]; then
	echo "********** TRACEROUTE ERROR **********"
	return 1
    else
	echo "traceroute $2 finished successfully."
	return 0
    fi
}

# Usage: stopNode node
stopNode () {
#    himage $1 kill -9 -1 2> /dev/null
#    himage $1 tcpdrop -a 2> /dev/null
    for ifc in `himage $1 netstat -i | tail -n +3 | cut -d' ' -f1`; do
	if [ "$ifc" != "lo0" ]; then
	    himage $1 ifconfig $ifc down
	fi
    done
    echo "Stopped node $1."
}

# Usage: startNode node
startNode () {
#    himage $1 kill -9 -1 2> /dev/null
#    himage $1 tcpdrop -a 2> /dev/null
    for ifc in `himage $1 netstat -i | tail -n +3 | cut -d' ' -f1`; do
	if [ "$ifc" != "lo0" ]; then
	    himage $1 ifconfig $ifc up
	fi
    done
    echo "Started node $1."
}

# Usage: dnsCheck node server
dnsCheck () {
    echo ""
    echo "########## HOST LOOKUP $1 $2"
    himage $1 host $2
    if [ $? -ne 0 ]; then
	echo "********** LOOKUP ERROR **********"
	return 1
    fi
    return 0
}

# Usage: sendMail sender_node e-mail
sendMail () {
    echo ""
    echo "########## Sending mail from $1 to $2"
    himage $1 Mail -s TEST $2 < $0
    if [ $? -ne 0 ]; then
	echo "********** SEND MAIL ERROR **********"
	return 1
    else
	return 0
    fi
}

# Usage: getMail getter_node pop3
getMail () {
    echo ""
    echo "########## Reading mail on $1 $2"
    #mes=`himage $1 mailtool -index INBOX $2`
    if test `uname -s` == "Linux"; then
        mes=`himage -b $1 nc $2 110 < getMail | wc -l | sed 's/ //g'`
    else
        mes=`himage $1 nc $2 110 < getMail | wc -l | sed 's/ //g'`
    fi
    if [ $mes -lt 7 ]; then
	echo "********** RECEIVE MAIL ERROR **********"
	return 1
    else
	return 0
    fi
}

# Usage: webCheck node server
webCheck () {
    echo ""
    echo "########## Fetching file from $2 to $1"
    fetch=fetch
    if test `uname -s` == "Linux"; then
        fetch=curl
    fi
    himage $1 $fetch -o - $2
    if [ $? -ne 0 ]; then
	echo "********** WEB (FETCH) ERROR **********"
	return 1
    else
	return 0
    fi
}
