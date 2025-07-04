#! /bin/sh

. ../common/procedures.sh

if [ $# -eq 1 ]; then
    moon="moon@$1"
    sun="sun@$1"
else
    moon="moon"
    sun="sun"
fi

himage -nt $moon killall -q charon
himage -nt $sun killall -q charon

if isOSlinux; then
    DIR="/etc/swanctl/"
    himage -nt $moon /usr/lib/ipsec/charon &
    himage -nt $sun /usr/lib/ipsec/charon &
else
    DIR="/usr/local/etc/swanctl/"
    kldload ipsec > /dev/null 2>&1
    himage -nt $moon /usr/local/libexec/ipsec/charon &
	himage -nt $moon ifconfig eth1 inet6 -ifdisabled
    himage -nt $sun /usr/local/libexec/ipsec/charon &
	himage -nt $sun ifconfig eth0 inet6 -ifdisabled
fi

started=0
steps=50
for i in `seq 1 $steps`
do
    himage $moon swanctl --stats > /dev/null 2>&1
    er1=$?
    himage $sun swanctl --stats > /dev/null 2>&1
    er2=$?
    [ $er1 -eq 0 -a $er2 -eq 0 ] && started=1 && break
    sleep 0.1
done

test $started -eq 0 && exit 1

hcp moon64_swanctl.conf ${moon}:${DIR}/swanctl.conf
hcp sun64_swanctl.conf ${sun}:${DIR}/swanctl.conf

hcp -r moon/* $moon:${DIR}/
hcp -r sun/* $sun:${DIR}/

himage -nt $moon swanctl --load-all
himage -nt $sun swanctl --load-all

steps=50
for i in `seq 1 $steps`
do
    himage $moon swanctl --list-conns 2>&1 | grep ^[[:space:]]*net64-net64: >/dev/null
    er1=$?
    himage $sun swanctl --list-conns 2>&1 | grep ^[[:space:]]*net64-net64: >/dev/null
    er2=$?
    [ $er1 -eq 0 -a $er2 -eq 0 ] && exit 0
    sleep 0.1
done

exit 1
