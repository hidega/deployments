ARG BASE_IMAGE

FROM $BASE_IMAGE

ARG FILESERVER_TASKS
ARG ENTRY_POINT

COPY tmp /tmp

RUN . "$FILESERVER_TASKS" \
    [ "$?" -ne "0" ] && echo "Error 1" && set -e && exit 1 \
    devon_create_fileserver \
    apk del jq

ENTRYPOINT ["$ENTRY_POINT"]

