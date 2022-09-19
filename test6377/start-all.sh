#!/bin/bash

cp ../../paleozoic/devonian/build-tasks/build_tasks.sh .

. ./build_tasks.sh

TEST_CONSTANTS="$(cat ./constants.json)"

function get_constant() {
  local expr=$1

  echo $(devon_get_json_property "$TEST_CONSTANTS" $expr)
}

MONITOR_IMAGE_NAME=$(get_constant ".monitor.imageName")
MONITOR_IMAGE_TAG=$(get_constant ".monitor.imageTag")
MONITOR_IMAGE_FULL_NAME=$MONITOR_IMAGE_NAME":"$MONITOR_IMAGE_TAG

FILESERVER_IMAGE_NAME=$(get_constant ".fileserver.imageName")
FILESERVER_IMAGE_TAG=$(get_constant ".fileserver.imageTag")
FILESERVER_IMAGE_FULL_NAME=$FILESERVER_IMAGE_NAME":"$FILESERVER_IMAGE_TAG
FILESERVER_HOSTNAME=$(get_constant ".fileserver.hostname")

MARIADB_PRIMARY_IMAGE_NAME=$(get_constant ".mariadbPrimary.imageName")
MARIADB_PRIMARY_IMAGE_TAG=$(get_constant ".mariadbPrimary.imageTag")
MARIADB_PRIMARY_IMAGE_FULL_NAME=$MARIADB_PRIMARY_IMAGE_NAME":"$MARIADB_PRIMARY_IMAGE_TAG
MARIADB_PRIMARY_HOSTNAME=$(get_constant ".mariadbPrimary.hostname")

MARIADB_SECRET=mariadb_secret
MARIADB_ROOTPWD=mariadbpwd

function create_network() {
  $DEVON_OCI network prune -f
  devon_exit_if_last_failed 101

  $DEVON_OCI network create --subnet $IP_BASE".0/24"
  devon_exit_if_last_failed 102

  echo $(podman network ls | grep cni | awk '{print $2}')
}

function cleanup() {
  $DEVON_OCI container rm -af
  sleep 2
  $DEVON_OCI image rm -f $MARIADB_PRIMARY_IMAGE_FULL_NAME $MONITOR_IMAGE_FULL_NAME $FILESERVER_IMAGE_FULL_NAME
}

function build_monitor() {
  cd ./monitor
  ./image.sh b $MONITOR_IMAGE_FULL_NAME
  cd ..  
}

function start_monitor() {
  local network=$1

  $DEVON_OCI run -d --rm  \
     --name=monitor \
     --network=$network \
     --ip="$IP_BASE.120" \
     --hostname=monitor \
     $MONITOR_IMAGE_FULL_NAME
  devon_exit_if_last_failed 401
}

function build_mariadb_primary() {
  cd ./mariadb-primary
  ./image.sh b
  cd .. 
}

function start_mariadb_primary() {
  $DEVON_OCI run -d --rm  \
     --name=mariadb \
     --network=$1 \
     --ip="$IP_BASE.130" \
     --hostname=mariadb \
     $MARIADB_IMAGE_FULL_NAME $MARIADB_ROOTPWD $MARIADB_SECRET
  devon_exit_if_last_failed 301
}

function build_fileserver() {
  cd ./fileserver
  ./image.sh b
  cd .. 
}

function start_fileserver() {
  $DEVON_OCI run -d --rm  \
     --name=fileserver \
     --network=$1 \
     --ip="$IP_BASE.140" \
     --hostname=$FILESERVER_HOSTNAME \
     $FILESERVER_IMAGE_FULL_NAME
  devon_exit_if_last_failed 201
}

exit 0

cleanup
NETWORK_NAME=$(create_network)
build_monitor
#build_mariadb_primary
#build_fileserver
start_monitor $NETWORK_NAME
#start_mariadb_primary $NETWORK_NAME
#start_fileserver $NETWORK_NAME

echo
echo "Services are started :)"
echo


