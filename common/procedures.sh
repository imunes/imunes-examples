#!/bin/sh

#
# PREAMBLE with checks and general output
#

# Before doing anything check for root rights.
if [ `id -u` -ne  0 ]; then
    echo "You must be root to run this script."
    exit 1
fi

# Start time measurement.
start_time=$(date +"%s")
echo "Starting experiment..."

#
# FUNCTIONS
#

os=`uname -s`;

isOSlinux() {
    if test $os = "Linux"; then
	true;
    else
	false;
    fi
}

isOSfreebsd() {
    if test $os = "FreeBSD"; then
	true;
    else
	false;
    fi
}

# Usage: thereWereErrors status
thereWereErrors () {
# End time measurment and output result.
    end_time=$(date +"%s")
    diff=$(($end_time-$start_time))
    echo "Test took $diff seconds."
    if [ $1 -ne 0 ]; then
	echo ""
	echo "There were errors."
    fi
}

# Usage: ping6Check source_node dest_address [count]
ping6Check () {
    echo ""
    echo "########## $1 pinging $2"
    if test -z "$3"; then
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
    if test -z "$3"; then
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
    if isOSfreebsd; then
	ip_addr=`himage $1 ifconfig $2 | awk '/inet /{print $2}'`
    else
	ip_addr=`himage $1 ip addr show $2 | awk '/inet /{print $2}'`
    fi

    if test -z "$ip_addr"; then
	echo ""
	echo "********** IFCONFIG ERROR **********"
	return 1
    else
	echo $ip_addr
	return 0
    fi
}

# Usage: getNodeIP6 node interface
getNodeIP6 () {
    if isOSfreebsd; then
	ip_addr=`himage $1 ifconfig $2 | awk '/inet6 /{print $2}' | grep -v $2`
    else
	ip_addr=`himage $1 ip -6 addr show $2 | awk '/inet6 .*global/{print $2}'`
    fi

    if test -z "$ip_addr"; then
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
    if isOSlinux; then
        himage $1 nohup sh -c "tcpdump -w /root/tcplog_$2 -ni $2 $args 2> tcplog_err_$2 &"
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
    if test -z "$1"; then
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
    if test -z "$strVal"; then
	echo "********** TRACEROUTE ERROR **********"
	return 1
    else
	echo "traceroute $2 finished successfully."
	return 0
    fi
}

# Usage: stopNode node
stopNode () {
    if isOSlinux; then
		ifaces=$(himage -nt $1 ls /sys/class/net)
    else
		ifaces=$(himage -nt $1 ifconfig -l)
    fi

    for ifc in $ifaces; do
	if [ "$ifc" != "lo0" ]; then
	    echo ifconfig $ifc down
	    himage $1 ifconfig $ifc down
	fi
    done
    echo "Stopped node $1."
}

# Usage: startNode node
startNode () {
    if isOSlinux; then
		ifaces=$(himage -nt $1 ls /sys/class/net)
    else
		ifaces=$(himage -nt $1 ifconfig -l)
    fi

    for ifc in $ifaces; do
	if [ "$ifc" != "lo0" ]; then
	    echo ifconfig $ifc up
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
    himage -nt $1 mail -s TEST $2 < $0
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
    if isOSlinux; then
        mes=`himage -nt $1 nc $2 110 < getMail | wc -l | sed 's/ //g'`
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
    if isOSlinux; then
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

# Usage: sleep n
# - countdown every 5 sec
Wait () {
    n=$1
    echo -n "Wait $n sec.."
    while test $n -gt 5
    do
        sleep 5
        n=$((n - 5))
        echo -n "$n.."
    done
    sleep $n
    echo ""
}

