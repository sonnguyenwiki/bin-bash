#!/bin/bash

set -euo pipefail
GREEN='\033[0;32m'
CLEAR='\033[0m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PREFIX='++'

sudo find var vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
sudo find var vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +;
sudo chown -R ${HOST_UID:-1000}:www-data . # Ubuntu
sudo chmod u+x bin/magento
printf "${GREEN}$PREFIX DONE => Set permission ${CLEAR}\n"
printf "${BLUE} Code compile... ${CLEAR}\n"
sudo php bin/magento se:up 
sudo php bin/magento se:di:co
sudo php bin/magento c:f
sudo php bin/magento se:sta:dep -f
sudo php bin/magento in:rei
printf "${GREEN}$PREFIX DONE => Code compile ${CLEAR}\n"
exit
