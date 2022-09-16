#!/bin/bash

IMAGE_COMMONS_DIR=../../../paleozoic/devonian/build-tasks

DEFAULT_USER="paleo"
DEFAULT_USER_ID="20001"
COMMON_SERVICE_PORT="8000"
SERVICE_DIR="/opt/service"
HEALTHCHECK_CMD="healthcheck.sh"
SERVICE_CMD="start.sh" 

OCI="podman --cgroup-manager=cgroupfs"
OCI_BUILD="$OCI build "

BASE_IMAGE="alpine:3.16"

IP_BASE="192.168.20"

MONITOR_IMAGE_NAME="test6377/monitor"
MONITOR_IMAGE_TAG="1"
MONITOR_IMAGE_FULL_NAME=$MONITOR_IMAGE_NAME":"$MONITOR_IMAGE_TAG

FILESERVER_IMAGE_NAME="test6377/fileserver"
FILESERVER_IMAGE_TAG="1"
FILESERVER_IMAGE_FULL_NAME=$FILESERVER_IMAGE_NAME":"$FILESERVER_IMAGE_TAG
FILESERVER_HOSTNAME=fileserver

MARIADB_PRIMARY_IMAGE_NAME="test6377/mariadb-primary"
MARIADB_PRIMARY_IMAGE_TAG="1"
MARIADB_PRIMARY_IMAGE_FULL_NAME=$MARIADB_IMAGE_NAME":"$MARIADB_IMAGE_TAG
MARIADB_PRIMARY_HOSTNAME=mariadb-primary

MARIADB_SECRET=mariadb_secret
MARIADB_ROOTPWD=mariadbpwd

function exit_if_last_failed() {
  ERR=$?
  [ "$ERR" -ne "0" ] && echo "*** Failure $1 ($ERR)" && set -e && exit 1
}

function build_image() {
  IMAGE=$1
  PARAMS=$2
  echo "Building image $IMAGE"
  $OCI image rm -f $IMAGE
  $OCI_BUILD --no-cache $PARAMS \
             --build-arg BASE_IMAGE=$BASE_IMAGE \
             --build-arg COMMON_SERVICE_PORT=$COMMON_SERVICE_PORT \
             --build-arg SERVICE_DIR=$SERVICE_DIR \
             --build-arg SERVICE_CMD=$SERVICE_CMD \
             --build-arg HEALTHCHECK_CMD=$HEALTHCHECK_CMD \
             -t $IMAGE .
  exit_if_last_failed $IMAGE
  echo
  echo "Image successfully built: $IMAGE"
}
