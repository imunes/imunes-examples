#! /bin/sh

ipfw -q flush
cmd="ipfw add"
ks="keep-state"
skip="skipto 5000"
pif=eth0
good_tcpo="22,23,25,53,80,443,110"

$cmd allow all from any to any via eth1               # LAN traffic
$cmd allow all from any to any via lo0                # loopback
$cmd deny  all from any to 192.168.1.0/24 in via $pif # without NAT
$cmd divert natd ip from any to any in via $pif
$cmd check-state

# Authorized inbound packets
$cmd $skip tcp from 15.16.17.25 to 192.168.1.10 25 setup $ks

# Authorized outbound packets
$cmd $skip udp from any to 15.16.17.18 53 out via $pif $ks
$cmd $skip tcp from any to any $good_tcpo out via $pif setup $ks
$cmd $skip icmp from any to any out via $pif $ks
$cmd deny log all from any to any

# skipto location for outbound stateful rules
$cmd 5000 divert natd ip from any to any out via $pif 
$cmd allow ip from any to any

