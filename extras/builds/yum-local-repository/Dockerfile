FROM centos:7

RUN mkdir -p "/var/www/html/repos/{base,centosplus,extras,updates}" \
    && yum install epel-release nginx createrepo yum-utils \
    && reposync -g -l -d -m --repoid=base --newest-only --download-metadata --download_path=/var/www/html/repos/ \
    && reposync -g -l -d -m --repoid=centosplus --newest-only --download-metadata --download_path=/var/www/html/repos/ \
    && reposync -g -l -d -m --repoid=extras --newest-only --download-metadata --download_path=/var/www/html/repos/ \
    && reposync -g -l -d -m --repoid=updates --newest-only --download-metadata --download_path=/var/www/html/repos/ \
    && createrepo -g comps.xml /var/www/html/repos/base/ \
    && createrepo -g comps.xml /var/www/html/repos/centosplus/ \
    && createrepo -g comps.xml /var/www/html/repos/extras/ \
    && createrepo -g comps.xml /var/www/html/repos/updates/

COPY repos.conf /etc/nginx/conf.d/
COPY repo_sync.sh /opt/repo_sync.sh

VOLUME /var/www/html/repos

EXPOSE 8081