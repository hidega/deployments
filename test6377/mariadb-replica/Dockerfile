FROM devonian/mariadb:1

COPY opt /opt

ARG BASE_IMAGE 
ARG DEFAULT_USER 
ARG DEFAULT_USER_ID 
ARG IMG_BASE_URL 
ARG SERVICE_ID_FILE

RUN mkdir -p /opt/data/mariadb && \
    chown -cR mysql /opt && \
    chgrp -cR mysql /opt && \
    chmod -c 755 /opt/prg/mariadb/scripts/start.sh

ENTRYPOINT ["/opt/prg/mariadb/scripts/start.sh"]
