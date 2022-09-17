#!/bin/bash

. ./commons.sh

function create_network() {
  $OCI network prune -f
  devon_exit_if_last_failed 101
  $OCI network create --subnet $IP_BASE".0/24"
  devon_exit_if_last_failed 102
  echo $(podman network ls | grep cni | awk '{print $2}')
}

function cleanup() {
  $OCI container rm -af
  $OCI image rm -f $MARIADB_IMAGE_FULL_NAME $MONITOR_IMAGE_FULL_NAME $FILESERVER_IMAGE_FULL_NAME
}

function build_monitor() {
  cd ./monitor
  ./image.sh b
  cd ..  
}

function start_monitor() {
  $OCI run -d --rm  \
     --name=monitor \
     --network=$1 \
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
  $OCI run -d --rm  \
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
  $OCI run -d --rm  \
     --name=fileserver \
     --network=$1 \
     --ip="$IP_BASE.140" \
     --hostname=$FILESERVER_HOSTNAME \
     $FILESERVER_IMAGE_FULL_NAME
  devon_exit_if_last_failed 201
}

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
