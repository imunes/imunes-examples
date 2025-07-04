#
# make 
# make certs      - make CA cert and certs for moon and sun
# make copy_certs - copy created certificates to ${IPSEC_DIR}
# make clean      - cleanup
#

IPSEC_DIR="../"

all:
	@make certs
	@make copy_certs

certs:
	@sh make_certificates.sh

copy_certs:
	@cp moonCert.pem ${IPSEC_DIR}/moon/x509
	@cp moonKey.pem  ${IPSEC_DIR}/moon/private
	@cp sunCert.pem ${IPSEC_DIR}/sun/x509
	@cp sunKey.pem  ${IPSEC_DIR}/sun/private
	@cp strongswanCert.pem ${IPSEC_DIR}/moon/x509ca
	@cp strongswanCert.pem ${IPSEC_DIR}/sun/x509ca

clean:
	@rm -fr *.pem index.* serial* newcerts .rand

