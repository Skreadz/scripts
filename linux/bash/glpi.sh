#!/bin/bash

sudo apt install -y apache2 php8.1 php8.1-curl php8.1-zip php8.1-gd php8.1-intl php8.1-intl php-pear php8.1-imagick php8.1-imap
sudo apt install -y php-memcache php8.1-pspell php8.1-tidy php8.1-xmlrpc php8.1-xsl php8.1-mbstring php8.1-ldap php8.1-ldap php-cas php-apcu
sudo apt install -y libapache2-mod-php8.1 php8.1-mysql php-bz2
sudo apt install -y mysql-server mysql-client
 
read -p "Saisir le nom de la base de données : " glpibdd
read -p "Saisir user base de données : " userbdd
read -p "Saisir le password de la base de données : " pwbdd
 
sudo mysql -e "CREATE DATABASE $glpibdd;"
sudo mysql -e "CREATE USER '$userbdd'@'%' IDENTIFIED BY '$pwbdd';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $glpibdd.* TO '$userbdd'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"
 
sudo openssl req -nodes -newkey rsa:2048 -sha256 -x509 -days 3650  -keyout /etc/ssl/private/glpi.key -out /etc/ssl/certs/glpi.crt
 
sudo chown www-data:www-data /etc/ssl/private/glpi.key
sudo chown www-data:www-data /etc/ssl/certs/glpi.crt
 
sudo timedatectl set-timezone Europe/Paris
 
sudo wget https://github.com/glpi-project/glpi/releases/download/10.0.10/glpi-10.0.10.tgz
 
sudo tar -xvf glpi-10.0.10.tgz
 
sudo mv glpi /var/www/html/
 
sudo bash -c "echo 'ServerName 127.0.0.1' >> /etc/apache2/apache2.conf"
 
sudo touch /etc/apache2/sites-available/glpi.conf
 
sudo cat << EOF > /etc/apache2/sites-available/glpi.conf
    <VirtualHost *:443>
        ServerName glpi
        DocumentRoot /var/www/html/glpi/
 
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
 
        <Directory /var/www/html/glpi/>
            Require all granted
            Options FollowSymlinks MultiViews
            AllowOverride All
       </Directory>
 
       <IfModule mod_headers.c>
         Header always set Strict-Transport-Security "max-age=15768000; includeSubDomains"
       </IfModule>
 
       SSLEngine on
       SSLCertificateFile    /etc/ssl/certs/glpi.crt
       SSLCertificateKeyFile   /etc/ssl/private/glpi.key
 
    </VirtualHost>
EOF
 
sudo cat << EOF > /var/www/html/glpi/.htaccess
# /var/www/glpi/.htaccess
RewriteBase /
RewriteEngine On
RewriteCond %{REQUEST_URI} !^/public
RewriteRule ^(.*)$ public/index.php [QSA,L]
EOF
 
sudo sed -i "s/;session.cookie_secure =/session.cookie_secure = 1/g" /etc/php/8.1/apache2/php.ini
sudo sed -i "s/session.cookie_httponly =/session.cookie_httponly = 1/g" /etc/php/8.1/apache2/php.ini
 
sudo a2enmod ssl
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2ensite glpi.conf
sudo systemctl reload apache2
 
sudo chown -R www-data:www-data /var/www/html/glpi/