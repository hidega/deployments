#!/bin/bash

. ../commons.sh

if [ "$1" == "b" ]
then
  rm -rf ./opt
  mkdir -p ./opt/cert
  cp ../cert/* ./opt/cert
  build_image $MONITOR_IMAGE_FULL_NAME "--squash-all"
  exit_if_last_failed "cannot build $MONITOR_IMAGE_FULL_NAME"
fi

if [ "$1" == "r" ]
then 
  $OCI container rm -f monitor
  $OCI run --rm -it -d --name monitor $MONITOR_IMAGE_FULL_NAME
  exit_if_last_failed "cannot run $MONITOR_IMAGE_FULL_NAME"
fi

