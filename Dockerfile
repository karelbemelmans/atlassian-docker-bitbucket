FROM java:openjdk-8-jre
MAINTAINER Karel Bemelmans <mail@karelbemelmans.com>

ENV BITBUCKET_VERSION 4.7.1
ENV DOWNLOAD_URL      https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-

ENV BITBUCKET_HOME          /var/atlassian/application-data/bamboo
ENV BITBUCKET_INSTALL_DIR   /opt/atlassian/bamboo

# Use the default unprivileged account. This could be considered bad practice
# on systems where multiple processes end up being executed by 'daemon' but
# here we only ever run one process anyway.
ENV RUN_USER            daemon
ENV RUN_GROUP           daemon

# Install git, download and extract Stash and create the required directory layout.
# Try to limit the number of RUN instructions to minimise the number of layers that will need to be created.
RUN apt-get update -qq                                                         \
    && apt-get install -y --no-install-recommends git                          \
    && apt-get clean autoclean                                                 \
    && apt-get autoremove --yes                                                \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN mkdir -p $BITBUCKET_INSTALL_DIR

RUN curl -L --silent                     ${DOWNLOAD_URL}${BITBUCKET_VERSION}.tar.gz | tar -xz --strip=1 -C "$BITBUCKET_INSTALL_DIR" \
    && mkdir -p                          ${BITBUCKET_INSTALL_DIR}/conf/Catalina      \
    && chmod -R 700                      ${BITBUCKET_INSTALL_DIR}/conf/Catalina      \
    && chmod -R 700                      ${BITBUCKET_INSTALL_DIR}/logs               \
    && chmod -R 700                      ${BITBUCKET_INSTALL_DIR}/temp               \
    && chmod -R 700                      ${BITBUCKET_INSTALL_DIR}/work               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BITBUCKET_INSTALL_DIR}/logs               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BITBUCKET_INSTALL_DIR}/temp               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BITBUCKET_INSTALL_DIR}/work               \
    && chown -R ${RUN_USER}:${RUN_GROUP} ${BITBUCKET_INSTALL_DIR}/conf

# Outside the container
#RUN rm /opt/atlassian/bamboo/conf/server.xml \
#  && ln -s /var/atlassian/application-data/bamboo/configuration/${BITBUCKET_VERSION}/conf/server.xml /opt/atlassian/bamboo/conf/server.xml

USER ${RUN_USER}:${RUN_GROUP}

VOLUME ["${BITBUCKET_INSTALL_DIR}"]

# HTTP Port
EXPOSE 7990

WORKDIR $BITBUCKET_INSTALL_DIR

# Run in foreground
CMD ["./bin/start-bitbucket.sh", "-fg"]
