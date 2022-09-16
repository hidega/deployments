#!/bin/sh

 # requires nothing

COMMON_SERVICE_PORT="8000"
SERVICE_DIR="/opt/service"
HEALTHCHECK_CMD="healthcheck.sh"
SERVICE_CMD="start.sh"
IMG_BASE_URL="https://people.inf.elte.hu/hiaiaat/img"
BASE_IMAGE="alpine:3.16"

function exit_if_last_failed() {
  local err=$?
  [ "$err" -ne "0" ] && echo "*** Failure $1 ($err)" && set -e && exit 1
}

function assert_equals_str() {
  [ "$1" != "$2" ] && echo -e "Assertion failure:
 $1
not equals
 $2
" && set -e && exit 1
}

jq --version > /dev/null

exit_if_last_failed "jq is not found"

function get_json_property() {
  local result=$(echo $1 | jq $2 | tr -d \")
  exit_if_last_failed "Cannot get JSON property - $1 $2"
  echo "$result"
}

# requires image commons.sh

USER_NAME=$(get_json_property "$1" ".userName")
USER_ID=$(get_json_property "$1" ".userId")
DATA_DIR=$(get_json_property "$1" ".dataDir")
PORT=$(get_json_property "$1" ".port")
SERVICE_DIR=$(get_json_property "$1" ".serviceDir")
HEALTHCHECK_CMD=$(get_json_property "$1" ".healthcheckCmd")
START_CMD=$(get_json_property "$1" ".startCmd")

apk add curl busybox-extras
exit_if_last_failed "cannot install packages"

adduser -H -D -u $USER_ID -s /bin/sh $USER_NAME
exit_if_last_failed "cannot add user $USER_NAME/$USER_ID"

mkdir -p $DATA_DIR
exit_if_last_failed "cannot create data dir $DATA_DIR"

mkdir -p $SERVICE_DIR
exit_if_last_failed "cannot create service dir $SERVICE_DIR"

echo -e "#!/bin/sh
su -s /bin/sh -c 'httpd -f -p \`hostname -i\`:$PORT -h $DATA_DIR > /dev/null 2>&1' $USER_NAME
" > $SERVICE_DIR/$START_CMD
exit_if_last_failed "cannot add start cmd"

echo -e "#!/bin/sh
curl \`hostname -i\`:$PORT/ping
" > $SERVICE_DIR/$HEALTHCHECK_CMD
exit_if_last_failed "cannot add healthcheck cmd"

echo "0" > $DATA_DIR/ping
exit_if_last_failed "cannot add ping file"

chmod -cR 755 $SERVICE_DIR/
exit_if_last_failed "cannot chmod service dir"

chown -cR $USER_NAME $SERVICE_DIR/
exit_if_last_failed "cannot chown service dir to $USER_NAME"

chown -cR $USER_NAME $DATA_DIR/
exit_if_last_failed "cannot chown data dir"

exit 0
