#!/bin/bash

. ../build_tasks.sh

MONITOR_IMAGE_FULL_NAME=$2
CMD=$1

if [ "$CMD" == "b" ]
then
  rm -rf ./opt
  mkdir -p ./opt/cert
  cp ../cert/* ./opt/cert
  devon_build_image $MONITOR_IMAGE_FULL_NAME "--squash-all"
  devon_exit_if_last_failed "cannot build $MONITOR_IMAGE_FULL_NAME"
fi

if [ "$CMD" == "r" ]
then 
  $DEVON_OCI container rm -f monitor
  $DEVON_OCI run --rm -it -d --name monitor $MONITOR_IMAGE_FULL_NAME
  devon_exit_if_last_failed "cannot run $MONITOR_IMAGE_FULL_NAME"
fi

