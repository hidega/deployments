#!/bin/bash

. ../commons.sh

if [ "$1" == "b" ] 
then
  rm -rf ./tmp
  mkdir ./tmp
  SETUP_SCRIPT=/tmp/setup.sh
  cat $IMAGE_COMMONS_DIR/image_commons.sh $IMAGE_COMMONS_DIR/fileserver_tasks.sh > .$SETUP_SCRIPT
  echo -e "#!/bin/sh\n\n `cat .$SETUP_SCRIPT`" > .$SETUP_SCRIPT
  build_image $FILESERVER_IMAGE_FULL_NAME "--build-arg=USER_NAME=$DEFAULT_USER --build-arg=USER_ID=$DEFAULT_USER_ID --build-arg=SETUP_SCRIPT=$SETUP_SCRIPT"
fi

[ "$1" == "r" ] && $OCI run --rm -it --name "monitor" $FILESERVER_IMAGE_FULL_NAME
