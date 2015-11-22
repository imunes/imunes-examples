#! /bin/sh

echo ""
echo "Scan private address of LAN-SMTP in LAN from smtpMM in DMZ"
echo "Everything should be filtered"
himage smtpMM nmap -Pn -p20-25,53,80 192.168.1.10

echo ""
echo "Scan private address of LAN-SMTP in LAN from outside network"
echo "Everything should be filtered"
himage pc nmap -Pn -p20-25,53,80 192.168.1.10

echo ""
echo "Scan outside address of LAN-SMTP in LAN from smtpMM in DMZ"
echo "NAT redirects 15.16.17.2:25 to 192.168.1.10:25"
echo "Only smtp tcp port should be open"
himage smtpMM nmap -Pn -p20-25,53,80 15.16.17.2

echo ""
echo "Scan outside address of LAN-SMTP in LAN from outside network"
echo "(internal smtp server for LAN)"
echo "Everything should be closed"
himage pc nmap -Pn -p20-25,53,80 15.16.17.2

echo ""
echo "Scan wwwMM.mm.com from outside network"
echo "Open: http"
himage pc nmap -Pn -p20-25,53,80 wwwMM.mm.com

echo ""
echo "Scan dnsMM.mm.com from outside network"
echo "Open: domain"
himage pc nmap -Pn -p20-25,53,80 dns.mm.com

echo ""
echo "Scan smtpMM.mm.com from outside network"
echo "Open: smtp"
himage pc nmap -Pn -p20-25,53,80 smtpMM.mm.com

echo ""
echo "Scan www.tel.fer.hr from DMZ"
echo "Open: smtp (http is not allowed from DMZ)"
himage smtpMM nmap -Pn -p20-25,53,80 www.tel.fer.hr

echo ""
echo "Scan www.tel.fer.hr from LAN"
echo "Open: smtp,http"
himage pc1 nmap -Pn -p20-25,53,80 www.tel.fer.hr

echo ""
echo "Scan UDP prots on dnsMM.mm.com from outside network"
echo "Open: domain (63 open|filtered)"
himage pc nmap -Pn -p7-70 -sU dns.mm.com

