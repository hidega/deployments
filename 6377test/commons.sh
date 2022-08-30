#!/bin/bash

DEFAULT_USER="paleo"
DEFAULT_USER_ID="20001"
COMMON_SERVICE_PORT="8000"
SERVICE_DIR="/opt/service"
HEALTHCHECK_CMD="healthcheck.sh"
SERVICE_CMD="start.sh"
PING_PATH="ping"
SERVICE_ID_FILE="/etc/service_id"

OCI="podman --cgroup-manager=cgroupfs"
OCI_BUILD="$OCI build "

IMG_BASE_URL="https://people.inf.elte.hu/hiaiaat/img"
BASE_IMAGE="alpine:3.16"

IP_BASE="192.168.20"

MONITOR_IMAGE_NAME="6377test/monitor"
MONITOR_IMAGE_TAG="1"
MONITOR_IMAGE_FULL_NAME=$MONITOR_IMAGE_NAME":"$MONITOR_IMAGE_TAG

FILESERVER_IMAGE_NAME="6377test/fileserver"
FILESERVER_IMAGE_TAG="1"
FILESERVER_IMAGE_FULL_NAME=$FILESERVER_IMAGE_NAME":"$FILESERVER_IMAGE_TAG
FILESERVER_HOSTNAME=fileserver

MARIADB_IMAGE_NAME="6377test/mariadb"
MARIADB_IMAGE_TAG="1"
MARIADB_IMAGE_FULL_NAME=$MARIADB_IMAGE_NAME":"$MARIADB_IMAGE_TAG
MARIADB_SECRET=mariadb_secret
MARIADB_ROOTPWD=mariadbpwd

function devon_exit_if_last_failed() {
  ERR=$?
  [ "$ERR" -ne "0" ] && echo "*** Failure $1 ($ERR)" && exit 1
}

function devon_build_image() {
  IMAGE=$1
  PARAMS=$2
  echo "Building image $IMAGE"
  $OCI image rm -f $IMAGE
  $OCI_BUILD --no-cache $PARAMS \
             --build-arg BASE_IMAGE=$BASE_IMAGE \
             --build-arg IMG_BASE_URL=$IMG_BASE_URL \
             --build-arg DEFAULT_USER_ID=$DEFAULT_USER_ID \
             --build-arg SERVICE_ID_FILE=$SERVICE_ID_FILE \
             --build-arg DEFAULT_USER=$DEFAULT_USER \
             -t $IMAGE .
  devon_exit_if_last_failed $IMAGE
  echo
  echo "Image successfully built: $IMAGE"
}


