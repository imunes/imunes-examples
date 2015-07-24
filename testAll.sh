#!/bin/sh

if [ "`whoami`" != "root" ]; then
    echo "Run this as root!"
    echo ""
    exit 1
fi

imunes -i

tests="DHCP DNS+Mail+WEB OSPF Ping RIP Traceroute functional_tests/rj45_vlan"

echo "#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*"
echo "# Starting background tests in:"
echo -n "# "
for dir in $tests; do
    echo -n "$dir "
    cd $dir
    if [ "$dir" == "ipsec/" ]; then
	for i in 44 46 64 66; do
	    sh "test${i}.sh" > TESTRESULTS_$i 2>&1 &
	    pids="$pids $!"
	done
    else
	sh test.sh > TESTRESULTS 2>&1 &
	pids="$pids $!"
    fi
    cd ..
done

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
echo "Finished."

grep "^There were errors." */TESTRESULTS* > /dev/null 2>&1
if test $? -eq 0
then
    echo ""
    echo "Please look at the logs:"
    grep "^There were errors." */TESTRESULTS* */*/TESTRESULTS*
else
    echo "OK."
fi
