#!/bin/bash

. ../commons.sh

[ "$1" == "b" ] && devon_build_image $FILESERVER_IMAGE_FULL_NAME

[ "$1" == "r" ] && $OCI run --rm -it --name "monitor" $FILESERVER_IMAGE_FULL_NAME
