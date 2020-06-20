#!/usr/bin/env bash

PLUGIN_NAME="
alexanderzobnin-zabbix-app,
grafana-clock-panel,
grafana-simple-json-datasource,
grafana-worldmap-panel
"

docker build -t monitoring/grafana:v0.0.1 \
--build-arg "GRAFANA_VERSION=latest" \
--build-arg "GF_INSTALL_PLUGINS=${PLUGIN_NAME}" \
-f grafana.Dockerfile .
