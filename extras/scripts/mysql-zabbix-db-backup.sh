#!/bin/bash

DATA=$(date --date='5 days ago' "+%Y/%m/%d")
TIME_STAMP=$(date -d "${DATA} 21:00:00" +"%s")
INSPECT_ZABBIX_SERVER=$(docker container inspect zabbix-server-mysql)
ZABBIX_DB_PASSWORD=$(docker container inspect zabbix-server-mysql \
        |grep -i "MYSQL_PASSWORD=" \
        |awk -F "\"," '{ print $1 }' \
        |awk -F "MYSQL_PASSWORD=" '{ print $2 }'
)

if test ! -z "${DATA}"
then

    if true; then
        cat << EOF > zabbix-cleanup-history_text.sql
SET @TIME_STAMP := $TIME_STAMP;

CREATE TABLE IF NOT EXISTS history_text_new LIKE history_text;

INSERT INTO history_text_new SELECT * FROM history_text WHERE clock > @TIME_STAMP;

ALTER TABLE history_text RENAME history_text_old;

ALTER TABLE history_text_new RENAME history_text;

TRUNCATE history_text_old;

DROP TABLE IF EXISTS history_text_old;

OPTIMIZE TABLE history_text;
EOF
    fi

    if true; then
        cat << EOF > zabbix-cleanup-history_uint.sql
SET @TIME_STAMP := $TIME_STAMP;

CREATE TABLE IF NOT EXISTS history_uint_new LIKE history_uint;

INSERT INTO history_uint_new SELECT * FROM history_uint WHERE clock > @TIME_STAMP;

ALTER TABLE history_uint RENAME history_uint_old;

ALTER TABLE history_uint_new RENAME history_uint;

TRUNCATE history_uint_old;

DROP TABLE IF EXISTS history_uint_old;

OPTIMIZE TABLE history_uint;
EOF
    fi

    if true; then
        cat << EOF > zabbix-cleanup-history.sql
SET @TIME_STAMP := $TIME_STAMP;

CREATE TABLE IF NOT EXISTS history_new LIKE history;

INSERT INTO history_new SELECT * FROM history WHERE clock > @TIME_STAMP;

ALTER TABLE history RENAME history_old;

ALTER TABLE history_new RENAME history;

TRUNCATE history_old;

DROP TABLE IF EXISTS history_old;

OPTIMIZE TABLE history;
EOF
    fi

    if true; then
        cat << EOF > zabbix-cleanup-trends.sql
SET @TIME_STAMP := $TIME_STAMP;

CREATE TABLE IF NOT EXISTS trends_new LIKE trends;

INSERT INTO trends_new SELECT * FROM trends WHERE clock > @TIME_STAMP;

ALTER TABLE trends RENAME trends_old;

ALTER TABLE trends_new RENAME trends;

TRUNCATE trends_old;

DROP TABLE IF EXISTS trends_old;

OPTIMIZE TABLE trends;
EOF
    fi

    # Stop Container Stack
    docker container stop \
    zabbix-server-mysql zabbix-web-nginx-mysql grafana

    # Create Backup
    docker exec -i mysql-server \
    mysqldump -u zabbix -p${ZABBIX_DB_PASSWORD} zabbix | gzip > db-$(date +\%d\%m\%Y\%H\%M\%S).gz

    # Execute Cleanup on zabbix Database
    docker exec -i mysql-server mysql -u zabbix -p${ZABBIX_DB_PASSWORD} zabbix < zabbix-cleanup-history_uint.sql \
        && docker exec -i mysql-server mysql -u zabbix -p${ZABBIX_DB_PASSWORD} zabbix < zabbix-cleanup-history.sql \
        && docker exec -i mysql-server mysql -u zabbix -p${ZABBIX_DB_PASSWORD} zabbix < zabbix-cleanup-trends.sql

    # Start Container Stack
    docker container start zabbix-server-mysql zabbix-web-nginx-mysql grafana \
        && sleep 5

    # Status
    STATUS_CODE=$(curl -o /dev/null -s -w "%{http_code}\n" http://localhost:8080/zabbix)

    API_VERSION=$(curl -s --location --request POST 'http://localhost:8080/api_jsonrpc.php' --header 'Content-Type: application/json' --data '{
    "jsonrpc": "2.0",
    "method": "apiinfo.version",
    "id": 0,
    "auth": null,
    "params": {}
    }')

    # Verify if Zabbix Server and UI is Up!
    if test ! -z "${API_VERSION}" || "${STATUS_CODE}" == "200"
    then
        docker container ls
    else
        echo  "[ERROR] $(date +\%d\%m\%Y\%H\%M\%S): ${API_VERSION}" > backup.err
        echo -e "Something Wrong!!, Check backup.err"
    fi

    rm -rf ./*.sql
    find ./ -name "*.gz" -type f -mtime +5 -exec rm -f {} \;

else

    echo -e "Please see option in --help"

fi