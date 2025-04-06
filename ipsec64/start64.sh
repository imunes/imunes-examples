#! /bin/sh

. ../common/procedures.sh

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
	kldload ipsec > /dev/null 2>&1
fi

hcp moon64_ipsec.conf $moon:${DIR}/ipsec.conf
hcp sun64_ipsec.conf $sun:${DIR}/ipsec.conf

hcp -r moon/* $moon:${DIR}/
hcp -r sun/* $sun:${DIR}/

if isOSfreebsd; then
	himage $moon ifconfig eth1 inet6 -ifdisabled
	himage $sun ifconfig eth0 inet6 -ifdisabled
fi

himage -nt $moon ipsec start
himage -nt $sun ipsec start

steps=50
for i in `seq 1 $steps`
do
    himage $moon ipsec statusall 2>&1 | grep ^[[:space:]]*net64-net64: >/dev/null
    er1=$?
    himage $sun ipsec statusall 2>&1 | grep ^[[:space:]]*net64-net64: >/dev/null
    er2=$?
    [ $er1 -eq 0 -a $er2 -eq 0 ] && himage $moon ipsec up net64-net64 && exit 0
    sleep 0.1
done

exit 1
