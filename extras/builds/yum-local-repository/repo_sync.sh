#!/bin/bash
##specify all local repositories in a single variable
LOCAL_REPOS=”base centosplus extras updates”
##a loop to update repos one at a time 
for REPO in ${LOCAL_REPOS}; do
    reposync -g -l -d -m --repoid=$REPO --newest-only --download-metadata --download_path=/var/www/html/repos/
    createrepo -g comps.xml /var/www/html/repos/$REPO/
    sleep 604800
done