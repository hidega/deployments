#!/bin/bash

. ../commons.sh

[ "$1" == "b" ] && devon_build_image $MARIADB_IMAGE_FULL_NAME "--squash-all"

[ "$1" == "r" ] && $OCI run --name "mariadb-localtest" -h $MARIADB_HOSTNAME $MARIADB_IMAGE_FULL_NAME $MARIADB_ROOTPWD $MARIADB_SECRET

