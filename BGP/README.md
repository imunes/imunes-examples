# BGP
BGP routing protocol examples

#### BGP_custom-config.imn
In this example "Custom Config" feature is used for BGP router's configuration.

Double click on router or select "Configure" from right-click popup menu:
- Custom startup config is "Enabled"
- Selected custom config is "conf1"
- Click on "Editor" button

(configuration is taken from: "Configuring and Testing Border Gateway
Protocol (BGP) on Basis of Cisco Hardware and Linux Gentoo with Quagga
Package (Zebra)": http://hosteddocs.ittoolbox.com/ke032707.pdf)

#### BGP-Anycast.imn
This is the example of BGP router configuration inserted directly in .imn file.
```
vi BGP-Anycast.imn
```
In this example BGP Anycast routing is demonstrated:
- IP address 8.8.8.8 is assigned to WEB1 and WEB2. 
- Client1 is redirected to WEB1 and Client2 is redirected to WEB2.
- If the link between Backbone1 and DC2 is configured to have BER=1 (or loss=100% for Linux), than after some time the traffic from Client2 is redirected to WEB1.

