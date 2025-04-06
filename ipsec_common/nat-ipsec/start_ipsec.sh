#! /bin/sh

. ../../common/procedures.sh

if [ $# -eq 1 ]; then
    moon="moon@$1"
    sun="sun@$1"
else
    moon="moon"
    sun="sun"
fi

if isOSlinux; then
    DIR="/etc"
else
    DIR="/usr/local/etc"
fi

hcp -r moon/* ${moon}:${DIR}/
hcp -r sun/* ${sun}:${DIR}/

himage -nt $moon ipsec start
himage -nt $sun ipsec start

sleep 1

himage $moon ipsec up net-net
