# syntax = docker/dockerfile:1.0-experimental
FROM openjdk:8-jre-buster

ENV DEBIAN_FRONTEND=noninteractive

ARG sap_cc_version=sapcc-2.13.2-linux-x64.tar.gz

ENV env_sap_cc_version=$sap_cc_version
ENV sap_cc_base_url=https://tools.hana.ondemand.com/additional

ENV SAP_CC_BASE_DIR=/opt/sap/scc
ENV SAP_SCC_PORT=8443

RUN apt-get update

# install openjdk
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates \
					       wget \
					       lsof procps # needed for some obscure embedded commmand in the software

RUN wget --no-check-certificate --no-cookies --header "Cookie: eula_3_1_agreed=tools.hana.ondemand.com/developer-license-3_1.txt; path=/;" -S $sap_cc_base_url/$sap_cc_version -O /tmp/sapcc.tar.gz && \
    mkdir -p /opt/sap \
    && useradd -u 1000 -m -d $SAP_CC_BASE_DIR -s /bin/bash scc \
    && tar xvfz /tmp/sapcc.tar.gz -C $SAP_CC_BASE_DIR \
    && chown -R scc:scc /opt/sap

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN  chmod +x /usr/local/bin/docker-entrypoint.sh \
     && ln -s /usr/local/bin/docker-entrypoint.sh / # for backwards compatibility

# cleanup and set permissions
RUN apt-get clean && \
    rm -rf /tmp/*

USER scc
# create init directories
RUN mkdir /opt/sap/scc-init \
    && cp -rf $SAP_CC_BASE_DIR/conf /opt/sap/scc-init/ \
    && cp -rf $SAP_CC_BASE_DIR/config /opt/sap/scc-init/ \
    && cp -rf $SAP_CC_BASE_DIR/config_master /opt/sap/scc-init/ \
    && cp -rf $SAP_CC_BASE_DIR/scc_config /opt/sap/scc-init/ \
    && mkdir -p /opt/sap/scc-init/configuration \
    && rm -rf $SAP_CC_BASE_DIR/conf \
    && rm -rf $SAP_CC_BASE_DIR/config \
    && rm -rf $SAP_CC_BASE_DIR/config_master \
    && rm -rf $SAP_CC_BASE_DIR/scc_config

WORKDIR /opt/sap/scc

ENTRYPOINT ["/docker-entrypoint.sh"]
