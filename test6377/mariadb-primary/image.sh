#!/bin/bash

. ../commons.sh

if [ "$1" == "b" ] 
then
  CERT_DIR=./opt/prg/mariadb/cert
  rm -rf $CERT_DIR
  mkdir -p $CERT_DIR
  cp ../cert/*.bin $CERT_DIR
  devon_build_image $MARIADB_IMAGE_FULL_NAME "--squash-all"
fi

[ "$1" == "r" ] && $OCI run --name "mariadb-localtest" -h $MARIADB_HOSTNAME $MARIADB_IMAGE_FULL_NAME $MARIADB_ROOTPWD $MARIADB_SECRET

