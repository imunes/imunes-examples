#! /bin/sh

. ../../common/procedures.sh

error() {
    echo $*
    exit 2
}

himage nat@$1 hostname \
  || error "Is simulation started? Try: Experiment->Execute"

if isOSlinux; then
    himage nat@$eid iptables-restore < nat.rules.linux
else
    kldload -n ipfw
    kldload -n ipdivert
    sleep 2
    himage nat@$1 natd -l -interface eth1
    hcp nat.rules nat@$1:/root
    himage nat@$1 sh /root/nat.rules
fi
