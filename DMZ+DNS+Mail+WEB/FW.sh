#! /bin/sh

ipfw -q flush
cmd="ipfw add"

$cmd check-state
$cmd allow ip from any to any via lo keep-state

$cmd deny ip from any to any not verrevpath in
# verrevpath: 
# drop all incoming packets coming to the system on the wrong interface; 
# a packet with a source address belonging to a host on a protected internal 
# network would be dropped if it tried to enter the system from 
# an external interface

# Allow RIP between FW and R9
$cmd allow udp from 10.0.1.1 to 10.0.1.2 dst-port 520
$cmd allow udp from me to 10.0.1.1 dst-port 520
$cmd allow udp from 10.0.1.1 to 224.0.0.9 dst-port 520
$cmd allow udp from me to 224.0.0.9 dst-port 520 out

# FW can be accessed only from LAN, using ssh 
$cmd allow tcp from 15.16.17.2 to me dst-port 22 in setup keep-state
$cmd deny  all from any to me

# Allow connections initiated from LAN (NAT interface on internal firewall)
$cmd allow ip  from 15.16.17.2 to any keep-state

# Allow access from Internet to servers on DMZ: smtpMM, wwwMM and dnsMM

# Mail server for mm.com, smtpMM: (receive and send e-mail)
$cmd allow tcp from any to 15.16.17.25 dst-port 25 setup keep-state
$cmd allow tcp from 15.16.17.25 to any dst-port 25 setup keep-state

# Web server for mm.com, wwwMM:
$cmd allow tcp from any to 15.16.17.80 dst-port 80 setup keep-state

# DNS server for mm.com, dnsMM:
$cmd allow tcp from any to 15.16.17.18 dst-port 53 setup keep-state
$cmd allow udp from any to 15.16.17.18 dst-port 53 keep-state

# dnsMM is DNS server for hosts in DMZ and LAN:
$cmd allow udp from 15.16.17.18 to any dst-port 53 keep-state

# deny|drop  --> filtered
# reset      --> closed
$cmd reset log ip from any to any

