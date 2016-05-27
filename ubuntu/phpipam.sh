#!/bin/bash
MYSQL_ROOT_PASSWORD="CHANGEME"

#Prepare mysql installation
debconf-set-selections <<< 'mysql-server mysql-server/root_password password '$MYSQL_ROOT_PASSWORD
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$MYSQL_ROOT_PASSWORD

#Get required packages
apt-get update
apt-get -y install apache2 mysql-server php5-mysql php5 libapache2-mod-php5 php5-mcrypt php5-gd php5-curl
wget http://pear.php.net/go-pear.phar
php go-pear.phar

#Download phpipam
wget -O phpipam-1.2.1.tar http://downloads.sourceforge.net/project/phpipam/phpipam-1.2.1.tar?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fphpipam%2F&ts=1464246235&use_mirror=kent
tar -xvf phpipam-1.2.1.tar -C /var/www

#CHANGE THE VIRTUAL HOST THIS IS DEFAULT (BAD) CCONFIGURATION
#Disable apache2 default conf and add a default host 
cd /etc/apache2/sites-available
a2dissite 000-default.conf
printf '<VirtualHost *:80>\n DocumentRoot /var/www/phpipam\n</VirtualHost>' > 001-phpipam.conf
a2ensite 001-phpipam.conf
a2enmod rewrite
service apache2 reload
 
#Create phpipam mysql user and db
mysql -u root -p$MYSQL_ROOT_PASSWORD << EOF
create database phpipam;
create user 'phpipam'@'localhost' identified by 'phpipamadmin';
GRANT ALL ON phpipam.* TO 'phpipam'@'localhost';
flush privileges;
quit
EOF

#populate db
cd /var/www/phpipam/db
mysql -u root -p$MYSQL_ROOT_PASSWORD phpipam < SCHEMA.sql
