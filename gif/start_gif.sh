#!/bin/sh

himage router1 sysctl net.link.gif.max_nesting=2
gif1=`himage router1 ifconfig gif create`
himage router1 ifconfig $gif1 tunnel 10.0.0.1 10.0.1.2
himage router1 ifconfig $gif1 inet6 fc00:1::100 fc00:3::100 prefixlen 128
himage router1 route add -inet6 fc00:4::/64 fc00:3::100

himage router2 sysctl net.link.gif.max_nesting=2
gif2=`himage router2 ifconfig gif create`
himage router2 ifconfig $gif2 tunnel 10.0.1.2 10.0.0.1
himage router2 ifconfig $gif2 inet6 fc00:3::100 fc00:1::100 prefixlen 128
himage router2 route add -inet6 fc00:0::/64 fc00:1::100
