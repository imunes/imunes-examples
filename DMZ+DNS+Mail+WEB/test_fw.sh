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
echo "Only smtp should be open"
himage smtpMM nmap -Pn -p20-25,53,80 15.16.17.2

echo ""
echo "Scan outside address of LAN-SMTP in LAN from outside network"
echo "(internal smtp server for LAN)"
echo "Everything should be filtered"
himage pc nmap -Pn -p20-25,53,80 15.16.17.2

echo ""
echo "Scan wwwMM.mm.com from outside network"
echo "Open: http"
himage pc nmap -Pn -p20-25,53,80 15.16.17.80

echo ""
echo "Scan dnsMM.mm.com from outside network"
echo "Everything should be filtered"
echo "Access to domain/tcp is allowed only from secondary server dnsTel"
himage pc nmap -Pn -p20-25,53,80 15.16.17.18

echo ""
echo "Scan dnsMM.mm.com from dnsTel"
echo "Open: domain (only from dnsTel: secundary server)"
himage dnsTel nmap -Pn -p20-25,53,80 15.16.17.18

echo ""
echo "Scan smtpMM.mm.com from outside network"
echo "Open: smtp"
himage pc nmap -Pn -p20-25,53,80 15.16.17.25

echo ""
echo "Scan www.tel.fer.hr from DMZ"
echo "Open: smtp (http is not allowed from DMZ)"
himage smtpMM nmap -Pn -p20-25,53,80 20.0.0.3

echo ""
echo "Scan www.tel.fer.hr from LAN"
echo "Open: smtp,http"
himage pc1 nmap -Pn -p20-25,53,80 20.0.0.3

echo ""
echo "Scan UDP ports on dnsMM.mm.com from outside network"
echo "Open: domain (63 open|filtered)"
himage pc nmap -Pn -p7-70 -sU 15.16.17.18

