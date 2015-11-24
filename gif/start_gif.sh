#!/bin/sh

. ../common/start_functions.sh

if [ $# -eq 1 ]; then
    eid=$1
    isEidRunning $eid
else
    eid=`isNodeRunning router1`
    if [ $? -ne 0 ]; then
	exit 1
    fi
fi

echo "Configuring gif tunnel on router1..."
himage router1@$eid sysctl net.link.gif.max_nesting=2
gif1=`himage router1@$eid ifconfig gif create`
himage router1@$eid ifconfig $gif1 tunnel 10.0.0.1 10.0.1.2
himage router1@$eid ifconfig $gif1 inet6 fc00:1::100 fc00:3::100 prefixlen 128
himage router1@$eid route add -inet6 fc00:4::/64 fc00:3::100
echo "Done."

echo "Configuring gif tunnel on router2..."
himage router2@$eid sysctl net.link.gif.max_nesting=2
gif2=`himage router2@$eid ifconfig gif create`
himage router2@$eid ifconfig $gif2 tunnel 10.0.1.2 10.0.0.1
himage router2@$eid ifconfig $gif2 inet6 fc00:3::100 fc00:1::100 prefixlen 128
himage router2@$eid route add -inet6 fc00:0::/64 fc00:1::100
echo "Done."
