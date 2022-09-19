#!/bin/bash

. ../build_tasks.sh

CMD=$1
PARAMS=$2

FILESERVER_IMAGE_FULL_NAME=$(devon_get_json_property "$PARAMS" "imageFullName")

function build_fileserver() {
  local fileserver_tasks="/tmp/fileserver_tasks.sh"
  local base_image=$(devon_get_json_property "$PARAMS" "baseImage")  
  local entry_point="$(devon_get_constant "service.serviceDir")/$(devon_get_constant "service.serviceCmd")"

  rm -rf ./tmp
  devon_exit_if_last_failed "cannot rm tmp"
  
  mkdir ./tmp
  devon_exit_if_last_failed "cannot create tmp"
  
  cp $(devon_get_json_property "$PARAMS" "tasksScript") .$fileserver_tasks
  devon_exit_if_last_failed "cannot copy build tasks"
  
  devon_build_image $FILESERVER_IMAGE_FULL_NAME "--build-arg=BASE_IMAGE=$base_image --build-arg=FILESERVER_TASKS=$fileserver_tasks --build-arg=ENTRY_POINT=$entry_point"
}

[ "$CMD" == "b" ] && build_fileserver

[ "$CMD" == "r" ] && $DEVON_OCI run --rm -it --name "monitor" $FILESERVER_IMAGE_FULL_NAME

