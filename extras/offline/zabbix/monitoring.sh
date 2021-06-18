#!/usr/bin/env bash

CONTAINER_NAME="
mysql-server
zabbix-server-mysql
zabbix-web-nginx-mysql
grafana
"

CONTAINER_IMAGES="
fabianoflorentino/mysql:latest
fabianoflorentino/zabbix-server-mysql:latest
fabianoflorentino/zabbix-web-nginx-mysql:latest
fabianoflorentino/grafana:latest
fabianoflorentino/orazabbix:latest
"


HELP="
Usage:
Local Host:

Look if you have Docker installed on local host.
In your local host, pull images from dockerhub, ./monitoring.sh --pull.
Save image on ./zabbix-container/extras/offline/ use, ./monitoring.sh --save

After download and save any images, create a compact and tar file with images and this script.

Remote Host:

Export vaiables ZABBIX_DB_PWD and MYSQL_ROOT_PWD

Ex. 
export ZABBIX_DB_PWD='<PASSWORD>'
export MYSQL_ROOT_PWD='<PASSWORD>'

and
Execute: ./monitoring <OPTION>

OBS: If is the first time to use this, use --load to load images on docker.

--help  Print this page

Local Host Commands:
--pull  Pull image from dockerhub
--save  Save image on docker local

Remote Host Commands:
--load  Load images of contianer on docker
--run   Start all containers
--stop  Stop all containers
--rmc   Remove all container from docker local
--rmi   Remove all images from docker local
--cls   List of container running
--clsa  List all containers
--lsi   List of images
"

function docker_pull() {

    DKC_VERSION=$(docker version |grep "Version:" |awk '{ print $2 }' |head -n1)
    
    if [ -z ${DKC_VERSION} ]
    then
        echo -e "\nPor favor instale o Docker na sua máquina - https://www.docker.com/get-started\n"
    else
        echo -e "\nCarregando as imagens localmente aguarde.........OK!\n" \
        && docker pull fabianoflorentino/mysql > /dev/null \
        && echo -e "Carregando a imagem localmente MySQL Server......OK!" \
        && docker pull fabianoflorentino/zabbix-server-mysql > /dev/null \
        && echo -e "Carregando a imagem localmente Zabbix Server.....OK!" \
        && docker pull fabianoflorentino/zabbix-web-nginx-mysql > /dev/null \
        && echo -e "Carregando a imagem localmente Zabbix Web........OK!" \
        && docker pull fabianoflorentino/grafana > /dev/null \
        && echo -e "Carregando a imagem localmente Grafana...........OK!" \
        && docker pull fabianoflorentino/orazabbix > /dev/null \
        && echo -e "Carregando a imagem localmente Orazabbix.........OK!\n"
    fi

}

function docker_save() {

    docker save -o ./fabianoflorentino-mysql.tar fabianoflorentino/mysql \
    && echo -e "\nSavando a imagem localmente MySQL Server......OK!" \
    && docker save -o ./fabianoflorentino-zabbix-server-mysql.tar fabianoflorentino/zabbix-server-mysql \
    && echo -e "Savando a imagem localmente Zabbix Server.....OK!" \
    && docker save -o ./fabianoflorentino-zabbix-web-nginx-mysql.tar fabianoflorentino/zabbix-web-nginx-mysql \
    && echo -e "Savando a imagem localmente Zabbix Web........OK!" \
    && docker save -o ./fabianoflorentino-grafana.tar fabianoflorentino/grafana \
    && echo -e "Savando a imagem localmente Grafana...........OK!" \
    && docker save -o ./fabianoflorentino-orazabbix.tar fabianoflorentino/orazabbix \
    && echo -e "Savando a imagem localmente Orazabbix.........OK!\n"

}

function docker_load() {
    
    docker load -q -i ./fabianoflorentino-mysql.tar \
    && docker load -q -i ./fabianoflorentino-zabbix-server-mysql.tar \
    && docker load -q -i ./fabianoflorentino-zabbix-web-nginx-mysql.tar \
    && docker load -q -i ./fabianoflorentino-grafana.tar \
    && docker load -q -i ./fabianoflorentino-orazabbix.tar

}

function mysql_server() {

    {

        docker run -d -t --restart unless-stopped --name mysql-server \
            -e MYSQL_DATABASE="zabbix" \
            -e MYSQL_USER="zabbix" \
            -e MYSQL_PASSWORD="${ZABBIX_DB_PWD}" \
            -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PWD}" \
            fabianoflorentino/mysql:latest \
            --character-set-server=utf8 --collation-server=utf8_bin

    } &> /dev/null && echo -e "\nIniciando MySQL Server.....OK!"

}

function zabbix_server_mysql() {

    {
    
        docker run -d -t --restart unless-stopped --name zabbix-server-mysql \
            -v zabbix-server-alertscripts:/usr/lib/zabbix/alertscripts \
            -v zabbix-server-externalscripts:/usr/lib/zabbix/externalscripts \
            -v zabbix-server-enc:/var/lib/zabbix/enc \
            -v zabbix-server-export:/var/lib/zabbix/export \
            -v zabbix-server-mibs:/var/lib/zabbix/mibs \
            -v zabbix-server-modules:/var/lib/zabbix/modules \
            -v zabbix-server-snmptraps:/var/lib/zabbix/snmptraps \
            -v zabbix-server-ssh_keys:/var/lib/zabbix/ssh_keys \
            -v zabbix-server-certs:/var/lib/zabbix/ssl/certs \
            -v zabbix-server-keys:/var/lib/zabbix/ssl/keys \
            -v zabbix-server-ssl_ca:/var/lib/zabbix/ssl/ssl_ca \
            -e DB_SERVER_HOST="mysql-server" \
            -e MYSQL_DATABASE="zabbix" \
            -e MYSQL_USER="zabbix" \
            -e MYSQL_PASSWORD="${ZABBIX_DB_PWD}" \
            -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PWD}" \
            -e ZBX_CACHESIZE=2048M \
            -p 10051:10051 \
            --link mysql-server:mysql \
            fabianoflorentino/zabbix-server-mysql:latest

    } &> /dev/null && echo -e "Iniciando Zabbix Server.....OK!"

}

function zabbix_web_nginx_mysql() {

    {
    
        docker run -d -t --restart unless-stopped --name zabbix-web-nginx-mysql \
            -e DB_SERVER_HOST="mysql-server" \
            -e MYSQL_DATABASE="zabbix" \
            -e MYSQL_USER="zabbix" \
            -e MYSQL_PASSWORD="${ZABBIX_DB_PWD}" \
            -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PWD}" \
            -e PHP_TZ="America/Sao_Paulo" \
            -p 8080:8080 \
            --link mysql-server:mysql \
            --link zabbix-server-mysql:zabbix-server \
            fabianoflorentino/zabbix-web-nginx-mysql:latest
    
    } &> /dev/null && echo -e "Iniciando Zabbix Web.....OK!"

}


function grafana() {

    {
    
        docker run -d -t --restart unless-stopped --name grafana \
        --link zabbix-web-nginx-mysql:zabbix-web-nginx-mysql \
        -p 3000:3000 \
        fabianoflorentino/grafana:latest
    
    } &> /dev/null && echo -e "Iniciando Grana.....OK!\n"

}

case $1 in
    --pull)
        docker_pull
        ;;
    --save)
        docker_save
        ;;
    --load)
        docker_load
        ;;
    --run)
        mysql_server
        zabbix_server_mysql
        zabbix_web_nginx_mysql
        grafana
        ;;
    --stop)
        docker container stop ${CONTAINER_NAME}
        ;;
    --rmc)
        docker container rm -f ${CONTAINER_NAME}
        ;;
    --rmi)
        docker image rm -f ${CONTAINER_IMAGES}
        ;;
    --cls)
        docker container ls
        ;;
    --clsa)
        docker container ls -a
        ;;
    --lsi)
        docker image ls
        ;;
    --help)
        echo -e "${HELP}"
        ;;
    *)
        echo -e "${HELP}"
        ;;
esac