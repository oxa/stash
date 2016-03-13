#!/bin/bash
#The home directory is also the app name
MYSQL_ROOT_PASSWORD="CHANGEME"
GUAC_PASSWORD="CHANGEME"
GUAC_HOME_DIR="/etc/guacamole"

#Update Everything
apt-get update && apt-get -y dist-upgrade

#Prepare mysql installation
debconf-set-selections <<< 'mysql-server mysql-server/root_password password '$MYSQL_ROOT_PASSWORD
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password '$MYSQL_ROOT_PASSWORD

#Install Stuff
apt-get -y install build-essential libcairo2-dev libpng12-dev libossp-uuid-dev libfreerdp-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev mysql-server mysql-client mysql-common mysql-utilities tomcat8

# Install libjpeg-turbo-dev
wget -O libjpeg-turbo-official_1.4.2_amd64.deb http://downloads.sourceforge.net/project/libjpeg-turbo/1.4.2/libjpeg-turbo-official_1.4.2_amd64.deb
dpkg -i libjpeg-turbo-official_1.4.2_amd64.deb

# Add GUACAMOLE_HOME to Tomcat8 ENV
echo "" >> /etc/default/tomcat8
echo "# GUACAMOLE EVN VARIABLE" >> /etc/default/tomcat8
echo "GUACAMOLE_HOME="$GUAC_HOME_DIR >> /etc/default/tomcat8

#Download Guacamole Files
wget -O guacamole-0.9.9.war http://downloads.sourceforge.net/project/guacamole/current/binary/guacamole-0.9.9.war
wget -O guacamole-server-0.9.9.tar.gz http://sourceforge.net/projects/guacamole/files/current/source/guacamole-server-0.9.9.tar.gz
wget -O guacamole-auth-jdbc-0.9.9.tar.gz http://sourceforge.net/projects/guacamole/files/current/extensions/guacamole-auth-jdbc-0.9.9.tar.gz
wget -O mysql-connector-java-5.1.38.tar.gz http://dev.mysql.com/get/Downloads/Connector/j/mysql-connector-java-5.1.38.tar.gz

#Extract Guac
tar -xzf guacamole-server-0.9.9.tar.gz
tar -xzf guacamole-auth-jdbc-0.9.9.tar.gz
tar -xzf mysql-connector-java-5.1.38.tar.gz

# MAKE DIRECTORIES
mkdir $GUAC_HOME_DIR
mkdir $GUAC_HOME_DIR/{lib,extensions}

# Install GUACD
cd guacamole-server-0.9.9
./configure --with-init-dir=/etc/init.d
make
make install
ldconfig
systemctl enable guacd
cd ..

# Move files to correct locations
mv guacamole-0.9.9.war $GUAC_HOME_DIR/guacamole.war
ln -s $GUAC_HOME_DIR/guacamole.war /var/lib/tomcat8/webapps/
cp mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar $GUAC_HOME_DIR/lib/
cp guacamole-auth-jdbc-0.9.9/mysql/guacamole-auth-jdbc-mysql-0.9.9.jar $GUAC_HOME_DIR/extensions/

# Configure guacamole.properties
echo "mysql-hostname: localhost" >> $GUAC_HOME_DIR/guacamole.properties
echo "mysql-port: 3306" >> $GUAC_HOME_DIR/guacamole.properties
echo "mysql-database: guacamole_db" >> $GUAC_HOME_DIR/guacamole.properties
echo "mysql-username: guacamole_user" >> $GUAC_HOME_DIR/guacamole.properties

# This is where you will want to change $GUAC_PASSWORD
echo "mysql-password: "$GUAC_PASSWORD >> $GUAC_HOME_DIR/guacamole.properties
rm -rf /usr/share/tomcat8/.guacamole
ln -s $GUAC_HOME_DIR /usr/share/tomcat8/.guacamole

mysql -u root -p$MYSQL_ROOT_PASSWORD << EOF
create database guacamole_db;
create user 'guacamole_user'@'localhost' identified by '$GUAC_PASSWORD';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';
flush privileges;
quit
EOF

# Build guacamole_db
cat guacamole-auth-jdbc-0.9.9/mysql/schema/*.sql | mysql -u root -p$MYSQL_ROOT_PASSWORD guacamole_db

# Cleanup Downloads
rm libjpeg-turbo-official_1.4.2_amd64.deb
rm guacamole-server-0.9.9.tar.gz
rm guacamole-auth-jdbc-0.9.9.tar.gz
rm mysql-connector-java-5.1.38.tar.gz

# Cleanup Folders
rm -rf mysql-connector-java-5.1.38/
rm -rf guacamole-auth-jdbc-0.9.9/
rm -rf guacamole-server-0.9.9/

# Restart Tomcat Service
service tomcat8 restart
service guacd restart
