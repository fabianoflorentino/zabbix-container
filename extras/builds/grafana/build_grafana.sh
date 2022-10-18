#!/usr/bin/env bash

PLUGIN_NAME="
grafana-clock-panel,
grafana-simple-json-datasource,
grafana-worldmap-panel,
alexanderzobnin-zabbix-app,
ibm-apm-datasource
"

docker build --no-cache -t fabianoflorentino/grafana:9.2.1 \
--build-arg "GRAFANA_VERSION=9.2.1" \
--build-arg "GF_INSTALL_PLUGINS=${PLUGIN_NAME}" \
-f Dockerfile .
