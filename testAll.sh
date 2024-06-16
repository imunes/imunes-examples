#!/bin/sh

if [ "`whoami`" != "root" ]; then
    echo "Run this as root!"
    echo ""
    exit 1
fi

. common/start_functions.sh

sequential=0
if test "$1" = "seq"; then
    sequential=1
fi

imunes -i

tests="DHCP DHCP6+RSOL DNS+Mail+WEB OSPF Ping RIP BGP Traceroute services ipsec functional_tests/rj45_vlan"

if isOSfreebsd; then
    tests="$tests gif"
fi

echo "#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*"
echo "# Running tests in:"
echo -n "# "
for dir in $tests; do
    echo -n "$dir "
    cd $dir
    if test "$dir" = "ipsec"; then
	for i in 44 46 64 66; do
	    if [ $sequential -eq 1 ]; then
		sh "test${i}.sh" > TESTRESULTS_$i 2>&1
	    else
		sh "test${i}.sh" > TESTRESULTS_$i 2>&1 &
		sleep 1
		pids="$pids $!"
	    fi
	done
    else
	if [ $sequential -eq 1 ]; then
	    sh test.sh > TESTRESULTS 2>&1
	else
	    sh test.sh > TESTRESULTS 2>&1 &
	    sleep 1
	    pids="$pids $!"
	fi
    fi
    cd - > /dev/null
done

if test ! -z "$pids" ; then
    running=1;
    echo ""
    echo "Some tests are still running in the background."
    echo "Please wait until everything has finished."
    echo ""
    echo -n "Running ."
    while test $running -eq 1
    do
	running=0
	for p in $pids
	do
	    ps $p > /dev/null 2>&1
	    if test $? -eq 0; then
		running=1
		sleep 3
		echo -n .
		break
	    fi
	done
    done
    echo ""
fi

echo "Finished."

grep "^There were errors." */TESTRESULTS* */*/TESTRESULTS* > /dev/null 2>&1
if test $? -eq 0
then
    echo ""
    echo "Please look at the logs:"
    grep "^There were errors." */TESTRESULTS* */*/TESTRESULTS*
    exit 1
else
    echo "OK."
fi
