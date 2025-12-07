#!/usr/bin/env bash

if [ "`whoami`" != "root" ]; then
    echo "Run this as root!"
    echo ""
    exit 1
fi

. common/start_functions.sh

# remove all old results
find . -type f -name 'TESTRESULTS*' -exec rm {} +

parallel_jobs=0
if test "$1" = "seq"; then
    parallel_jobs=1
elif test "$1" = "-j"; then
    parallel_jobs=$2
    if ! [[ "$parallel_jobs" =~ ^[0-9]+$ ]] || test $parallel_jobs -eq 0; then
	echo "Not able to run in parallel with '$parallel_jobs', try running:"
	echo "\$ $0 seq"
	echo "or"
	echo "\$ $0 -j [number_of_jobs]"
	echo ""
	exit 1
    fi
else
    parallel_jobs=$(($(nproc)/2))
	if test "$parallel_jobs" -eq 0; then
		parallel_jobs=1
	fi
fi

imunes -i

if test -z "$TESTS"; then
    # put longer tests near the beginning
    tests=(BGP DNS+Mail+WEB OSPF DHCP6+RSOL RIP DHCP Ping Traceroute services ipsec44 ipsec46 ipsec64 ipsec66 functional_tests/rj45 functional_tests/rj45_vlan functional_tests/extelem functional_tests/empty_ifaces)

    if isOSfreebsd; then
	tests+=('gif')
    fi
else
    tests=($TESTS)
fi

echo "#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*"
if test $parallel_jobs -eq 1; then
    echo "# Sequential mode"
else
    echo "# Parallel mode - max $parallel_jobs tests running in background"
    echo "# Please wait until everything has finished."
fi
test -z "$DETAILS" && echo -n "# "

next_idx=0
running_ctr=0
done_running=""
currently_running=""
old_done_running=""
old_currently_running=""
while true; do
    if test $next_idx -lt ${#tests[@]} && test $running_ctr -lt $parallel_jobs; then
	dir=${tests[$next_idx]}
	next_idx=$((next_idx+1))
	test -z "$DETAILS" && echo -n "$dir "

	if ! test -d "$dir"; then
	    continue
	fi

	cd $dir
	sh test.sh > TESTRESULTS 2>&1 &
	curpid=$!
	pidvar=pid_$curpid
	eval $pidvar=$dir
	pids="$pids $curpid"

	cd - > /dev/null

	if test -z "$SKIP_SLEEP"; then
	    sleep 3
	fi
    fi

    running_ctr=0
    new_pids=""
    currently_running=""
    for p in $pids; do
	pvar=pid_$p
	ps $p > /dev/null 2>&1
	if test $? -eq 0; then
	    running_ctr=$((running_ctr+1))
	    new_pids="$new_pids $p"
	    currently_running="$currently_running ${!pvar}"
	else
	    done_running="$done_running ${!pvar}"
	fi
    done

    if test -n "$DETAILS"; then
	if test "$done_running" != "$old_done_running" || test "$currently_running" != "$old_currently_running"; then
	    if test -n "$done_running" && test -n "$currently_running"; then
		echo -en "# DONE:$done_running | RUNNING:$currently_running\r"
	    elif test -n "$done_running"; then
		echo -en "# DONE:$done_running                                                                     \r"
	    elif test -n "$currently_running"; then
		echo -en "# RUNNING:$currently_running\r"
	    fi

	    old_done_running=$done_running
	    old_currently_running=$currently_running
	fi
    fi

    test -z "$new_pids" && test $next_idx -ge ${#tests[@]} && break
    pids=$new_pids

    sleep 1
done

echo ""
echo ""
echo "Finished."

if find . -type f -name 'TESTRESULTS*' -exec grep -q "^There were errors." {} +; then
    echo ""
    echo "Please look at the logs:"
    find . -type f -name 'TESTRESULTS*' -exec grep "^There were errors." {} +
    exit 1
else
    echo "OK."
fi
