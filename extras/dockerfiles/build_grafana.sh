#!/usr/bin/env bash

PLUGIN_NAME="
grafana-clock-panel,
grafana-simple-json-datasource,
grafana-worldmap-panel,
alexanderzobnin-zabbix-app,
ibm-apm-datasource
"

docker build --no-cache -t brgtsisdt3ptf001/grafana \
--build-arg "GRAFANA_VERSION=latest" \
--build-arg "GF_INSTALL_PLUGINS=${PLUGIN_NAME}" \
-f grafana.Dockerfile .