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
	@cp moonCert.pem ${IPSEC_DIR}/moon/ipsec.d/certs
	@cp moonKey.pem  ${IPSEC_DIR}/moon/ipsec.d/private
	@cp sunCert.pem ${IPSEC_DIR}/sun/ipsec.d/certs
	@cp sunKey.pem  ${IPSEC_DIR}/sun/ipsec.d/private
	@cp strongswanCert.pem ${IPSEC_DIR}/moon/ipsec.d/cacerts
	@cp strongswanCert.pem ${IPSEC_DIR}/sun/ipsec.d/cacerts

clean:
	@rm -fr *.pem index.* serial* newcerts .rand

