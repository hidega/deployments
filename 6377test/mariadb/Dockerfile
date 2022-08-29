FROM devonian/mariadb:1

COPY opt /opt

RUN mkdir -p /opt/data/mariadb && \
    chown -cR mysql /opt && \
    chgrp -cR mysql /opt && \
    chmod -c 755 /opt/prg/mariadb/scripts/start.sh

ENTRYPOINT ["/opt/prg/mariadb/scripts/start.sh"]
