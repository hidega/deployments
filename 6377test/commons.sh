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

function devon_exit_if_last_failed() {
  [ "$?" -ne "0" ] && echo "*** Failure $1" && exit 1
}

# image params
function devon_build_image() {
  echo "Building image $1"
  $OCI image rm -f $1
  $OCI_BUILD --no-cache $2 \
             --build-arg BASE_IMAGE=$BASE_IMAGE \
             --build-arg IMG_BASE_URL=$IMG_BASE_URL \
             --build-arg DEFAULT_USER_ID=$DEFAULT_USER_ID \
             --build-arg SERVICE_ID_FILE=$SERVICE_ID_FILE \
             --build-arg DEFAULT_USER=$DEFAULT_USER \
             -t $1 .
  devon_exit_if_last_failed $1
  echo
  echo "Image successfully built: $1"
}

# name image params
function devon_run_image() {
  $OCI run $3 --name $1 $2 /bin/sh
}

