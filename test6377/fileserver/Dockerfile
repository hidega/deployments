ARG BASE_IMAGE

FROM $BASE_IMAGE

ARG COMMON_SERVICE_PORT
ARG SERVICE_DIR
ARG HEALTHCHECK_CMD
ARG SERVICE_CMD
ARG USER_NAME
ARG USER_ID
ARG SETUP_SCRIPT

COPY tmp /tmp

RUN apk add jq && \
    chmod -c 755 $SETUP_SCRIPT && \
    PARAMS='{ "port":'$COMMON_SERVICE_PORT', "serviceDir":"'$SERVICE_DIR'", "healthcheckCmd":"'$HEALTHCHECK_CMD'", "startCmd":"'$SERVICE_CMD'", "userName":"'$USER_NAME'", "userId":'$USER_ID', "dataDir":"/opt/data" }' && \
    eval "$SETUP_SCRIPT '$PARAMS'" && \
    rm $SETUP_SCRIPT && \
    apk del jq

ENTRYPOINT ["$SERVICE_DIR/$SERVICE_CMD"]

