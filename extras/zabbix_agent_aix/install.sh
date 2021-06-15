#!/usr/bin/env sh

FILTER_1=$(netstat -nr | grep default | awk '{print  $6}')
IP_ADDR=$(ifconfig ${FILTER_1} | grep inet | head -n 1 | awk '{print $2}')

mkdir /etc/zabbix
mkdir /var/log/zabbix/
mkdir -p /usr/local/etc/
mkdir -p /var/run/zabbix/
mkdir -p /etc/zabbix/zabbix_agentd.d 

mkgroup zabbix
mkuser pgrp='zabbix' groups='zabbix' zabbix

cp ./bin/zabbix_* /bin/
cp ./sbin/zabbix_agent* /sbin/
cp ./zabbix_agentd.conf /etc/zabbix/

sed s/ListenIP=/ListenIP=${IP_ADDR}/g ./zabbix_agentd.conf \
> /etc/zabbix/zabbix_agentd.conf

ln -s /etc/zabbix/zabbix_agentd.conf /usr/local/etc/zabbix_agentd.conf

chown -R zabbix:zabbix /var/log/zabbix/
chown -R zabbix:zabbix /var/run/zabbix/

mkitab "zabbix:2:once:/sbin/zabbix_agentd >/dev/null 2>&1"

zabbix_agentd