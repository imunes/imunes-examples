#!/bin/sh

set -e

if [ `id -u` -ne  0 ]; then
    echo "You must be root to run this script."
    exit 1
fi

# get the right vmstat command that returns the free memory status
mfree() {
    if test "$os" = "FreeBSD"; then
	vmstat -H | tail -1 | awk '{print $5}'
    elif test "$os" = "Linux"; then
	vmstat | tail -1 | awk '{print $4}'
    fi
}

# generate a random experiment ID used for starting experiments
genEid() {
    echo i`tr -cd 'a-f0-9' </dev/urandom | head -c 5`
}

# start topology with IMUNES
# $1 - eid
# $2 - topology
startTopo() {
    imunes -b -e $1 $2 > start_$1.log
    egrep -o "[0-9]+\.[0-9]+ " start_$1.log
}

# terminate topology with IMUNES
# $1 - eid
termTopo() {
    imunes -b -e $1 > term_$1.log
    egrep -o "[0-9]+\.[0-9]+ " term_$1.log
}

#argument parsing
os=`uname -s`
count=10
wait_before_termination=10

if test "$1" = "-c"; then
    count=$2
    shift 2
fi

tests="$*"

# print system info
if test "$os" = "FreeBSD"; then
    imunes -i
    echo "CPU:`sysctl hw.model | cut -d: -f2`"
    echo "Cores:`sysctl hw.ncpu | cut -d: -f2`"
    mem_gb=$(echo "scale=2; `sysctl hw.realmem | cut -d: -f2`/1024/1024/1024" | bc -l)
elif test "$os" = "Linux"; then
    echo "CPU:`cat /proc/cpuinfo | grep "model name" | head -1 | cut -d: -f2`"
    echo "Cores: `cat /proc/cpuinfo | grep processor | wc -l`"
    mem_gb=$(echo "scale=2; `cat /proc/meminfo | grep MemTotal | awk '{print $2}'`/1024/1024" | bc -l)
else
    echo "OS not supported."
    exit 1
fi

echo "RAM: $mem_gb GB"
echo "Benchmarking topologies: $tests"
echo "Number of iterations: $count"

for t in $tests; do
    echo "Running topology: $t"
    freem_before_bench=`mfree`
    sum_start=0
    sum_term=0
    sum_memusage=0
    for i in $(seq 1 $count); do
	eid=`genEid`
	# measure free memory before
	freem_before=`mfree`
	echo -n "$i. eid: $eid "
	# start topology
	start_time=`startTopo $eid $t`
	echo -n "start: $start_time "
	# wait for topology stabilization
	sleep $start_time
	# wait before termination
	sleep $wait_before_termination
	# calculate memusage
	freem_after=`mfree`
	memusage=$(($freem_before-$freem_after))
	echo -n "memusage: $memusage "
	# terminate topology
	term_time=`termTopo $eid`
	echo "term: $term_time "
	# wait for system stabilization
	sleep $term_time
	freem_end=`mfree`
	# accumulate values for average
	sum_start=`echo $sum_start+$start_time | bc -l`
	sum_term=`echo $sum_term+$term_time | bc -l`
	sum_memusage=`echo $sum_memusage+$memusage | bc -l`
    done
    freem_after_bench=`mfree`
    avg_start=`echo "scale=3; $sum_start/$count" | bc -l`
    avg_term=`echo "scale=3; $sum_term/$count" | bc -l`
    avg_memusage=`echo "scale=0; $sum_memusage/$count" | bc -l`
    echo "Average startup time: $avg_start s"
    echo "Average termination time: $avg_term s"
    echo "Average memory usage: $avg_memusage KB"
    echo "Total memory leak: $(($freem_before_bench-$freem_after_bench)) KB"
done

#cleanup logs
rm -f *log
