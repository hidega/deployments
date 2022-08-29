#!/bin/bash

. ../commons.sh

IMAGE_NAME="devonian/mariadb-localtest"
IMAGE_TAG="1"
IMAGE_FULL_NAME=$IMAGE_NAME":"$IMAGE_TAG

HOSTNAME=mariadb1
ROOT_PWD=rootpwd
SECRET=secret

[ "$1" == "b" ] && devon_build_image $IMAGE_FULL_NAME "--squash-all"

[ "$1" == "r" ] && $OCI run --name "mariadb-localtest" -h $HOSTNAME $IMAGE_FULL_NAME $ROOT_PWD $HOSTNAME $SECRET
