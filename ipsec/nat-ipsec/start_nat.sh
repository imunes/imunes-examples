#! /bin/sh

error() {
    echo $*
    exit 2
}

kldload -n ipfw
kldload -n ipdivert

himage nat@$1 hostname \
  || error "Is simulation started? Try: Experiment->Execute"

sleep 2
himage nat@$1 natd -l -interface eth1
hcp nat.rules nat@$1:/root
himage nat@$1 sh /root/nat.rules
