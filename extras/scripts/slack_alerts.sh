#!/bin/sh

webhook_url=$1
message=$2

wget --no-check-certificate --post-data "payload={\"username\":\"Zabbix\", \"text\":\"$message\"}" $webhook_url -O -q