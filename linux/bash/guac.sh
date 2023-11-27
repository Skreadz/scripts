#!/bin/bash
sudo apt -y update && upgrade
sudo apt install -y make libswscale-dev freerdp2-dev make build-essential mysql-server mysql-client apache2
sudo apt install -y gcc g++ libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavformat-dev libavutil-dev
sudo apt install -y libpango1.0-dev libssh2-1-dev libvncserver-dev libtelnet-dev libssl-dev libvorbis-dev libwebp-dev libpango1.0-dev libwebsockets-dev libpulse-dev
 
sudo wget https://downloads.apache.org/guacamole/1.5.3/source/guacamole-server-1.5.3.tar.gz
sudo tar xzf guacamole-server-1.5.3.tar.gz
cd guacamole-server-1.5.3/
sudo ./configure --with-init-dir=/etc/init.d --disable-guacenc
sudo make
sudo make install
sudo ldconfig
sudo systemctl enable guacd
sudo systemctl start guacd
 
sudo apt install -y tomcat9 tomcat9-admin tomcat9-common tomcat9-user
 
sudo mkdir /etc/guacamole
 
sudo wget https://downloads.apache.org/guacamole/1.5.3/binary/guacamole-1.5.3.war -O /etc/guacamole/guacamole.war
 
sudo ln -s /etc/guacamole/guacamole.war /var/lib/tomcat9/webapps/
 
sudo systemctl restart tomcat9
sudo systemctl restart guacd
 
sudo mkdir /etc/guacamole/{extensions,lib}
 
sudo cat << EOF >> /etc/default/tomcat9
GUACAMOLE_HOME=/etc/guacamole
EOF
 
read -p "Saisir le nom de la base de données : " guacbdd
read -p "Saisir user base de données : " guacuserbdd
read -p "Saisir le password de la base de données : " guaccpwbdd
 
sudo mysql -e "CREATE DATABASE $guacbdd;"
sudo mysql -e "CREATE USER '$guacuserbdd'@'localhost' IDENTIFIED BY '$guaccpwbdd';"
sudo mysql -e "GRANT SELECT,INSERT,UPDATE,DELETE ON $guacbdd.* TO '$guacuserbdd'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
 
sudo wget https://downloads.apache.org/guacamole/1.5.3/binary/guacamole-auth-jdbc-1.5.3.tar.gz
 
sudo tar vfx guacamole-auth-jdbc-1.5.3.tar.gz
 
sudo cat guacamole-auth-jdbc-1.5.3/mysql/schema/*.sql | sudo mysql $guacbdd
sudo cp guacamole-auth-jdbc-1.5.3/mysql/guacamole-auth-jdbc-mysql-1.5.3.jar /etc/guacamole/extensions/
 
sudo wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-8.0.13.tar.gz
sudo tar xvzf mysql-connector-java-8.0.13.tar.gz
 
sudo cp mysql-connector-java-8.0.13/mysql-connector-java-8.0.13.jar /etc/guacamole/lib/
 
sudo cat << EOF >> /etc/guacamole/guacamole.properties
# Hostname and Guacamole server port
guacd-hostname: localhost
guacd-port: 4822
 
# MySQL properties
 
mysql-hostname: localhost
mysql-port: 3306
mysql-database: $guacbdd
mysql-username: $guacuserbdd
mysql-password: $guaccpwbdd
EOF
 
sudo ln -s /etc/guacamole /usr/share/tomcat9/.guacamole
 
sudo systemctl restart tomcat9
sudo systemctl restart guacd
 
sudo a2enmod proxy && sudo a2enmod proxy_http && sudo a2enmod ssl
 
sudo openssl req -nodes -newkey rsa:2048 -sha256 -x509 -days 3650  -keyout /etc/ssl/private/guacamole.key -out /etc/ssl/certs/guacamole.crt
 
sudo chown www-data:www-data /etc/ssl/private/guacamole.key
sudo chown www-data:www-data /etc/ssl/certs/guacamole.crt
 
sudo touch /etc/apache2/sites-available/guacamole.conf
 
sudo cat << EOF >> /etc/apache2/sites-available/guacamole.conf
<VirtualHost *:443>
 
     SSLEngine on
     SSLCertificateFile /etc/ssl/certs/guacamole.crt
     SSLCertificateKeyFile /etc/ssl/private/guacamole.key
 
     ProxyPreserveHost On
     ProxyRequests On
     ProxyPass / http://127.0.0.1:8080/guacamole/
     ProxyPassReverse / http://127.0.0.1:8080/guacamole/
 
</VirtualHost>
EOF
 
sudo cat << EOF >> /etc/apache2/apache2.conf
Servername 127.0.0.1
EOF
 
sudo a2ensite guacamole.conf
 
sudo systemctl restart apache2