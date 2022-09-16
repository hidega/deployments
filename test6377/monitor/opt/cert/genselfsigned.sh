#!/bin/bash

EXPIRES_DAYS=3650
TMP_FILE=/tmp/tempfile.txt

DOMAIN_SUBJECT="/C=HU/ST=Budapest/L=Budapest/O=Aleutian_Studio/OU=IT_Department/CN=aleutianstudio.hu"
DOMAIN_CSR_FILE=domain-csr.txt
DOMAIN_CERT_FILE=cert.pem
#DOMAIN_PK_PWD=""
DOMAIN_PK_SIZE=2048
DOMAIN_PK_FILE=key.pem
#DOMAIN_PK_PWD_PARAM="-des3 -passout pass:$DOMAIN_PK_PWD" 

ROOT_PK_FILE=root-key.pem
ROOT_CERT_FILE=ca.pem
ROOT_SUBJECT="/C=HU/ST=Budapest/L=Budapest/O=Master_Studio/OU=CEO_Department/CN=masterstudio.hu"

function exit_if_last_failed() {
  EXIT_CODE=$?
  [ $EXIT_CODE -ne "0" ] && echo "*** Failure $1 ($EXIT_CODE)" && exit $EXIT_CODE
}

openssl genrsa -out $DOMAIN_PK_FILE $DOMAIN_PK_SIZE
exit_if_last_failed "Cannot generate private key"

openssl req -key $DOMAIN_PK_FILE -new -out $DOMAIN_CSR_FILE -subj $DOMAIN_SUBJECT
exit_if_last_failed "Cannot generate domain CSR"

openssl req -x509 -sha256 -nodes -days $EXPIRES_DAYS -newkey rsa:2048 -keyout $ROOT_PK_FILE -out $ROOT_CERT_FILE -subj $ROOT_SUBJECT
exit_if_last_failed "Cannot generate root cerificate"

echo "authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
subjectAltName = @alt_names
[alt_names]
DNS.1 = somedomain.com
" > $TMP_FILE

openssl x509 -req -CA $ROOT_CERT_FILE -CAkey $ROOT_PK_FILE -in $DOMAIN_CSR_FILE -out $DOMAIN_CERT_FILE -days $EXPIRES_DAYS -CAcreateserial -extfile $TMP_FILE
exit_if_last_failed "Cannot generate domain cerificate"

echo
echo "Success :)"
echo
