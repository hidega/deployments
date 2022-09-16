#!/bin/bash

. ./../../../paleozoic/devonian/build-tasks/commons.sh

IMAGE_ID="3421test-gateway1"
IMAGE_NAME="devonian/$IMAGE_ID"
IMAGE_TAG="1"
IMAGE_FULL_NAME=$IMAGE_NAME":"$IMAGE_TAG

[ "$1" == "b" ] && devon_build_image $IMAGE_FULL_NAME "IMAGE_ID=$IMAGE_ID" && exit 0

[ "$1" == "r" ] && devon_run_rm_image $IMAGE_ID $IMAGE_FULL_NAME && exit 0

echo "Error"
exit 1

