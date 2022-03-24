#!/bin/bash

set -euo pipefail
GREEN='\033[0;32m'
CLEAR='\033[0m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PREFIX='++'

MYSQL_USER="root"
MYSQL=/usr/bin/mysql
MYSQL_PASSWORD="123"
IP="localhost"

#printf "I ${RED}love${NC} Stack Overflow\n"
printf "${GREEN}========== WELCOME TO CLI BY SON NGUYEN ==========\n${CLEAR}"
    read -p "ServerName(base_url): " base_url
    read -p "Path project(root_dir ex:/var/www/magento/): " root_dir
    
if [ ! -f /etc/apache2/sites-available/$base_url.conf ]; then
    sudo sh -c 'echo <VirtualHost *:80>
	ErrorLog /var/log/error.log
	ServerName '$base_url'
      DocumentRoot '$root_dir'
      <Directory '$root_dir'>
             Options +Indexes +Includes +FollowSymLinks +MultiViews
              AllowOverride All
              Require all granted
      </Directory>
      #SSLEngine on
        #SSLCertificateFile     /home/son/Documents/ssl/test-ssl.local.crt
        #SSLCertificateKeyFile /home/son/Documents/ssl/test-ssl.local.key	
	#CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" >> /etc/apache2/sites-available/'$base_url.conf

    printf "${GREEN}$PREFIX DONE => file '$base_url.conf' was created${CLEAR}\n"
else
    printf "${YELLOW}$PREFIX WARNING => file '$base_url.conf' already existed${CLEAR}\n"
fi

if [[ ! $(cat /etc/hosts) =~ '127.0.0.1 '$base_url'' ]]; then
    sudo sh -c 'echo "127.0.0.1 '$base_url'" >> /etc/hosts'
fi
printf "${GREEN}$PREFIX DONE => Added domain '$base_url' to /etc/hosts ${CLEAR}\n"
sudo a2ensite $base_url.conf	
sudo a2enmod rewrite
sudo service apache2 restart

printf "${BLUE}$PREFIX Install Magento ${CLEAR}\n"
if [ ! -f "$root_dir"app/etc/env.php ]; then
    cp env-example.php "$root_dir"app/etc/env.php
    printf "${GREEN}$PREFIX DONE => file env.php was created${CLEAR}\n"
else
    printf "${YELLOW}$PREFIX WARNING => file env.php already existed${CLEAR}\n"
fi

printf "${BLUE}$PREFIX Start Import Database ${CLEAR}\n"
read -p "Database name(*.sql ex: database_name): " db
   DB_NAME=$(echo $db | cut -f 1 -d '.')
   RESULT=`mysqlshow --user=$MYSQL_USER --password=$MYSQL_PASSWORD $db > /dev/null 2>&1 && echo $db || echo "Database does not exists"`

   if [ "$RESULT" == $db ]; then
    printf "${YELLOW}$PREFIX WARNING => database name '$db' already existed${CLEAR}\n"
    printf "${BLUE} Updating base_url... ${CLEAR}\n"
    SQL_UPDATE="use $DB_NAME;UPDATE core_config_data SET value = 'http://$base_url/' WHERE path='web/unsecure/base_url' OR path='web/secure/base_url' OR path='web/unsecure/base_media_url' OR path='admin/url/custom';
UPDATE core_config_data SET value = '' WHERE path='web/unsecure/base_media_url';"
   sudo mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD -e "$SQL_UPDATE"
   printf "${GREEN}$PREFIX DONE => update base url\n"
   else	
	   SQL="create database $DB_NAME;use $DB_NAME;GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'$IP';FLUSH PRIVILEGES;"
	   sudo mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD -e "$SQL"

	   if [ $? != "0" ]; then
	     #printf "${RED} [Error]: $SQL ${CLEAR}\n"
	     printf "${RED} [Error]: Database creation failed${CLEAR}\n"
	   else
	     printf "${GREEN}$PREFIX DONE => create database with name $DB_NAME ${CLEAR}\n"
	     printf "${BLUE} Importing... ${CLEAR}\n"
	   fi
	   if [  -f database/$db.sql ]; then
	    sudo mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD $db<database/$db.sql
	    printf "${GREEN}$PREFIX DONE => import database\n"
	    printf "${BLUE} Updating base_url... ${CLEAR}\n"
	    SQL_UPDATE="use $DB_NAME;UPDATE core_config_data SET value = 'http://$base_url/' WHERE path='web/unsecure/base_url' OR path='web/secure/base_url' OR path='web/unsecure/base_media_url' OR path='admin/url/custom';
	UPDATE core_config_data SET value = '' WHERE path='web/unsecure/base_media_url';"
	   sudo mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD -e "$SQL_UPDATE"
	   printf "${GREEN}$PREFIX DONE => update base url\n"
	   else
	    printf "${RED} [Error]: database/$db.sql not found${CLEAR}\n"
	   fi
   fi

cd $root_dir
./set-permission-and-compile.sh
printf "${GREEN}========== ALL DONE! ==========\n${CLEAR}"	
printf "front-end:http://$base_url \n"
printf "front-end:http://$base_url/admin \n"
if [ ! -f "$root_dir"app/etc/config.php ]; then
    printf "${YELLOW}$PREFIX WARNING => config.php file not found${CLEAR}\n"
fi

