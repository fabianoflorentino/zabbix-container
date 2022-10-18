# syntax=docker/dockerfile:1
# Base image to build Zabbix Server with MySQL support
FROM alpine:3.16 as base

ARG MAJOR_VERSION=6.0
ARG ZBX_VERSION=${MAJOR_VERSION}.9

ENV TERM=xterm \
  ZBX_VERSION=${ZBX_VERSION} \
  PATH=/usr/lib/jvm/default-jvm/bin:$PATH \
  JAVA_HOME=/usr/lib/jvm/default-jvm

LABEL org.opencontainers.image.authors="Alexey Pustovalov <alexey.pustovalov@zabbix.com>" \
  org.opencontainers.image.description="Zabbix build base image contains all required packages to build Zabbix images" \
  org.opencontainers.image.documentation="https://www.zabbix.com/documentation/${MAJOR_VERSION}/manual/installation/containers" \
  org.opencontainers.image.licenses="GPL v2.0" \
  org.opencontainers.image.title="Zabbix build base" \
  org.opencontainers.image.url="https://zabbix.com/" \
  org.opencontainers.image.vendor="Zabbix LLC" \
  org.opencontainers.image.version="${ZBX_VERSION}"

RUN set -eux && \
    INSTALL_PKGS="bash \
      autoconf \
      automake \
      coreutils \
      curl-dev \
      libevent-dev \
      libssh-dev \
      sqlite-dev \
      libmodbus-dev \
      libxml2-dev \
      mysql-dev \
      net-snmp-dev \
      openipmi-dev \
      openldap-dev \
      openssl-dev \
      pcre2-dev \
      postgresql-dev \
      openjdk8 \
      gettext \
      git \
      g++ \
      go \
      make \
      openjdk8-jre-base \
      unixodbc-dev" && \
    apk add \
      --no-cache \
      --clean-protected \
      ${INSTALL_PKGS} && \
    rm -rf /var/cache/apk/*


# syntax=docker/dockerfile:1
# MySQL base to buil Zabbix server with MySQL support
FROM base as mysql

ARG MAJOR_VERSION=6.0
ARG ZBX_VERSION=${MAJOR_VERSION}.9

ARG MAJOR_VERSION
ARG ZBX_VERSION
ARG ZBX_SOURCES=https://git.zabbix.com/scm/zbx/zabbix.git

LABEL org.opencontainers.image.authors="Alexey Pustovalov <alexey.pustovalov@zabbix.com>" \
  org.opencontainers.image.description="Zabbix build base for MySQL based images" \
  org.opencontainers.image.documentation="https://www.zabbix.com/documentation/${MAJOR_VERSION}/manual/installation/containers" \
  org.opencontainers.image.licenses="GPL v2.0" \
  org.opencontainers.image.source="${ZBX_SOURCES}" \
  org.opencontainers.image.title="Zabbix build base (MySQL)" \
  org.opencontainers.image.url="https://zabbix.com/" \
  org.opencontainers.image.vendor="Zabbix LLC" \
  org.opencontainers.image.version="${ZBX_VERSION}"

RUN set -eux && \
    ARCH_SUFFIX="$(arch)"; \
    case "$ARCH_SUFFIX" in \
      x86_64) \
        additional_components='--enable-java'; \
        ;; \
      aarch64) \
        additional_components='--enable-java'; \
        ;; \
      armv7l) \
        additional_components='--enable-java'; \
        ;; \
      s390x) \
        additional_components='--enable-java'; \
        ;; \
      ppc64le) \
        additional_components=''; \
        ;; \
      *) echo "Unknown ARCH_SUFFIX=${ARCH_SUFFIX-}"; exit 1 ;; \
    esac; \
    cd /tmp/ && \
    git -c advice.detachedHead=false clone ${ZBX_SOURCES} --branch ${ZBX_VERSION} --depth 1 --single-branch /tmp/zabbix-${ZBX_VERSION} && \
    cd /tmp/zabbix-${ZBX_VERSION} && \
    zabbix_revision=`git rev-parse --short HEAD` && \
    sed -i "s/{ZABBIX_REVISION}/$zabbix_revision/g" include/version.h && \
    sed -i "s/{ZABBIX_REVISION}/$zabbix_revision/g" src/go/pkg/version/version.go && \
    sed -i "s/{ZABBIX_REVISION}/$zabbix_revision/g" src/zabbix_java/src/com/zabbix/gateway/GeneralInformation.java && \
    ./bootstrap.sh && \
    export CFLAGS="-fPIC -pie -Wl,-z,relro,-z,now,-z,defs" && \
    export CFLAGS="$CFLAGS -D_FORTIFY_SOURCE=2 -fexceptions -O2 -pipe" && \
    ./configure \
      --datadir=/usr/lib \
      --libdir=/usr/lib/zabbix \
      --prefix=/usr \
      --sysconfdir=/etc/zabbix \
      --enable-agent \
      --enable-agent2 \
      --enable-ipv6 \
      --enable-proxy \
      --enable-server \
      --enable-webservice \
      --with-ldap \
      --with-libcurl \
      --with-libmodbus \
      --with-libpcre2 \
      --with-libxml2 \
      --with-mysql \
      --with-net-snmp \
      --with-openipmi \
      --with-openssl \
      --with-ssh \
      --with-unixodbc \
      $additional_components \
      --silent && \
    make -j"$(nproc)" -s dbschema && \
    make -j"$(nproc)" -s && \
    make -j"$(nproc)" -s gettext && \
    cat database/mysql/schema.sql > database/mysql/create.sql && \
    cat database/mysql/images.sql >> database/mysql/create.sql && \
    cat database/mysql/data.sql >> database/mysql/create.sql && \
    gzip -c database/mysql/create.sql > database/mysql/create_server.sql.gz && \
    rm -rf database/mysql/create.sql && \
    cat database/mysql/schema.sql > database/mysql/create.sql && \
    gzip -c database/mysql/create.sql > database/mysql/create_proxy.sql.gz && \
    rm -rf database/mysql/create.sql && \
    strip /tmp/zabbix-${ZBX_VERSION}/src/zabbix_agent/zabbix_agentd && \
    strip /tmp/zabbix-${ZBX_VERSION}/src/zabbix_server/zabbix_server && \
    strip /tmp/zabbix-${ZBX_VERSION}/src/zabbix_proxy/zabbix_proxy && \
    strip /tmp/zabbix-${ZBX_VERSION}/src/go/bin/zabbix_agent2 && \
    strip /tmp/zabbix-${ZBX_VERSION}/src/zabbix_get/zabbix_get && \
    strip /tmp/zabbix-${ZBX_VERSION}/src/zabbix_sender/zabbix_sender && \
    strip /tmp/zabbix-${ZBX_VERSION}/src/go/bin/zabbix_web_service


# syntax=docker/dockerfile:1
# Zabbix Server with MySQL database support
FROM mysql as zabbix-server-mysql

ARG MAJOR_VERSION=6.0
ARG ZBX_VERSION=${MAJOR_VERSION}.9
ARG BUILD_BASE_IMAGE=zabbix-build-mysql:alpine-${ZBX_VERSION}


FROM alpine:3.16

ARG MAJOR_VERSION=6.0
ARG ZBX_VERSION=${MAJOR_VERSION}.9
ARG ZBX_SOURCES=https://git.zabbix.com/scm/zbx/zabbix.git

ENV TERM=xterm \
  ZBX_VERSION=${ZBX_VERSION} ZBX_SOURCES=${ZBX_SOURCES} \
  MIBDIRS=/usr/share/snmp/mibs:/var/lib/zabbix/mibs MIBS=+ALL

LABEL org.opencontainers.image.authors="Alexey Pustovalov <alexey.pustovalov@zabbix.com>" \
  org.opencontainers.image.description="Zabbix server with MySQL database support" \
  org.opencontainers.image.documentation="https://www.zabbix.com/documentation/${MAJOR_VERSION}/manual/installation/containers" \
  org.opencontainers.image.licenses="GPL v2.0" \
  org.opencontainers.image.source="${ZBX_SOURCES}" \
  org.opencontainers.image.title="Zabbix server (MySQL)" \
  org.opencontainers.image.url="https://zabbix.com/" \
  org.opencontainers.image.vendor="Zabbix LLC" \
  org.opencontainers.image.version="${ZBX_VERSION}"

STOPSIGNAL SIGTERM

COPY --from=mysql ["/tmp/zabbix-${ZBX_VERSION}/src/zabbix_server/zabbix_server", "/usr/sbin/zabbix_server"]
COPY --from=mysql ["/tmp/zabbix-${ZBX_VERSION}/src/zabbix_get/zabbix_get", "/usr/bin/zabbix_get"]
COPY --from=mysql ["/tmp/zabbix-${ZBX_VERSION}/src/zabbix_sender/zabbix_sender", "/usr/bin/zabbix_sender"]
COPY --from=mysql ["/tmp/zabbix-${ZBX_VERSION}/conf/zabbix_server.conf", "/etc/zabbix/zabbix_server.conf"]
COPY --from=mysql ["/tmp/zabbix-${ZBX_VERSION}/database/mysql/create_server.sql.gz", "/usr/share/doc/zabbix-server-mysql/create.sql.gz"]
COPY ["docker-entrypoint-mysql.sh", "/usr/bin/docker-entrypoint.sh"]

RUN set -eux && \
  INSTALL_PKGS="bash \
    tini \
    fping \
    traceroute \
    nmap \
    tzdata \
    iputils \
    libcurl \
    libevent \
    libldap \
    libssh \
    libxml2 \
    mariadb-client \
    mariadb-connector-c \
    net-snmp-agent-libs \
    openipmi-libs \
    pcre2 \
    unixodbc" && \
  apk add \
    --no-cache \
    --clean-protected \
    ${INSTALL_PKGS} && \
  addgroup \
    --system \
    --gid 1995 \
  zabbix && \
  adduser \
    --system \
    --gecos "Zabbix monitoring system" \
    --disabled-password \
    --uid 1997 \
    --ingroup zabbix \
    --shell /sbin/nologin \
    --home /var/lib/zabbix/ \
    zabbix && \
  adduser zabbix root && \
  adduser zabbix dialout && \
  mkdir -p /etc/zabbix && \
  mkdir -p /var/lib/zabbix && \
  mkdir -p /usr/lib/zabbix/alertscripts && \
  mkdir -p /usr/lib/zabbix/dbscripts && \
  mkdir -p /var/lib/zabbix/dbscripts && \
  mkdir -p /var/lib/zabbix/enc && \
  mkdir -p /var/lib/zabbix/export && \
  mkdir -p /usr/lib/zabbix/externalscripts && \
  mkdir -p /var/lib/zabbix/mibs && \
  mkdir -p /var/lib/zabbix/modules && \
  mkdir -p /var/lib/zabbix/snmptraps && \
  mkdir -p /var/lib/zabbix/ssh_keys && \
  mkdir -p /var/lib/zabbix/ssl && \
  mkdir -p /var/lib/zabbix/ssl/certs && \
  mkdir -p /var/lib/zabbix/ssl/keys && \
  mkdir -p /var/lib/zabbix/ssl/ssl_ca && \
  mkdir -p /usr/share/doc/zabbix-server-mysql && \
  chown --quiet -R zabbix:root /etc/zabbix/ /var/lib/zabbix/ && \
  chgrp -R 0 /etc/zabbix/ /var/lib/zabbix/ && \
  chmod -R g=u /etc/zabbix/ /var/lib/zabbix/ && \
  chown --quiet -R zabbix:root /usr/bin/docker-entrypoint.sh && \
  chgrp -R 0 /usr/bin/docker-entrypoint.sh && \
  chmod +x /usr/bin/docker-entrypoint.sh && \
  rm -rf /var/cache/apk/*

EXPOSE 10051/TCP

WORKDIR /var/lib/zabbix

VOLUME ["/var/lib/zabbix/snmptraps", "/var/lib/zabbix/export"]

ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/docker-entrypoint.sh"]

USER 1997

CMD ["/usr/sbin/zabbix_server", "--foreground", "-c", "/etc/zabbix/zabbix_server.conf"]
