#! /bin/sh

export SubjectAltName
SubjectAltName=""

#####
# Create self-signed CA
#
openssl req -x509 -sha256 -newkey rsa:2048 -passout pass:1234 \
    -subj "/C=CH/O=Linux strongSwan/CN=strongSwan Root CA" \
    -keyout strongswanKey.pem -out strongswanCert.pem \
    -days 1460 \
    -set_serial 0 \
    -config openssl.cnf

#####
# Required files and dirs
#
if test ! -f serial; then
    echo "01" > serial
fi
if test ! -f index.txt; then
    touch index.txt
fi
if test ! -f index.txt.attr; then
    echo "unique_subject = no" > index.txt.attr
fi
if test ! -d newcerts; then
    mkdir newcerts
fi

#####
# Create and sign host certificates
#
hosts="sun moon"

for host in $hosts; do
  SubjectAltName=${host}.strongswan.org
  openssl req -newkey rsa:2048 -keyout ${host}Key.pem \
    -out ${host}Req.pem \
    -nodes \
    -subj "/C=CH/O=Linux strongSwan/CN=${host}.strongswan.org" \
    -config openssl.cnf
    
  openssl ca -in ${host}Req.pem -days 730 -out ${host}Cert.pem -notext \
    -passin pass:1234 \
    -batch \
    -config openssl.cnf
    
  openssl rsa -in ${host}Key.pem -out tempkeyfile
  mv tempkeyfile ${host}Key.pem 
done

#####
# View created certificates:
#
# openssl x509 -in strongswanCert.pem -text -noout | less
# openssl x509 -in sunCert.pem -text -noout | less
# openssl x509 -in moonCert.pem -text -noout | less

# Check public (cert) / private:

# openssl x509 -in moonCert.pem -modulus -noout
# openssl rsa -in moonKey.pem -modulus -noout

# openssl x509 -in sunCert.pem -modulus -noout
# openssl rsa -in sunKey.pem -modulus -noout

