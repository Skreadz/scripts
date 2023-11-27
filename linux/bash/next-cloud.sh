#!/bin/bash
sudo apt install -y apache2 libapache2-mod-php php-gd php-mysql mysql-server mysql-client unzip
sudo apt install -y php-curl php-mbstring php-intl php-gmp php-bcmath php-xml php-imagick php-zip
sudo apt install -y redis-server php-redis libmagickcore-6.q16-6-extra php-imagick imagemagick
 
sudo wget https://download.nextcloud.com/server/releases/latest.zip
 
sudo unzip latest.zip
 
sudo mv nextcloud /var/www/html/
 
sudo chown -R www-data:www-data /var/www/html/nextcloud
 
read -p "Saisir le nom de la base de données : " nextbdd
read -p "Saisir user base de données : " nextuserbdd
read -p "Saisir le password de la base de données : " nextpwbdd
 
sudo mysql -e "CREATE DATABASE IF NOT EXISTS $nextbdd CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
sudo mysql -e "CREATE USER '$nextuserbdd'@'localhost' IDENTIFIED BY '$nextpwbdd';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $nextbdd.* TO '$nextuserbdd'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
 
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nextcloud.key -out /etc/ssl/certs/nextcloud.crt
 
sudo chown www-data:www-data /etc/ssl/private/nextcloud.key
sudo chown www-data:www-data /etc/ssl/certs/nextcloud.crt
 
sudo touch /etc/apache2/sites-available/nextcloud.conf
 
sudo cat << EOF > /etc/apache2/sites-available/nextcloud.conf
<VirtualHost *:443>
ServerName nextcloud.shield.gouv
DocumentRoot /var/www/html/nextcloud
 
<Directory /var/www/html/nextcloud/>
 Require all granted
 Options FollowSymlinks MultiViews
 AllowOverride All
 <IfModule mod_dav.c>
 Dav off
 </IfModule>
</Directory>
 
SSLEngine on
SSLCertificateFile    /etc/ssl/certs/nextcloud.crt
SSLCertificateKeyFile   /etc/ssl/private/nextcloud.key
 
<IfModule mod_headers.c>
    Header always set Strict-Transport-Security "max-age=15768000; includeSubDomains"
</IfModule>
 
ErrorLog /var/log/apache2/yourdomain.com.error_log
CustomLog /var/log/apache2/yourdomain.com.access_log common
</VirtualHost>
EOF
 
sudo sed -i "s/memory_limit = 128M/memory_limit = 600M/g" /etc/php/8.1/apache2/php.ini

 
sudo a2enmod ssl
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2ensite nextcloud.conf
sudo systemctl reload apache2
 
read -p "Saisir le dossier pour le stockage nextcloud : " datanextcloud
 
sudo chown -R www-data:www-data $datanextcloud

#sudo sed -i "s/);/  'memcache.local' => '\\\OC\\\Memcache\\\Redis',\n  'redis' => array(\n     'host' => 'localhost',\n     'port' => 6379,\n     ),\n  'memcache.locking' => '\\\OC\\\Memcache\\\Redis',\n 'default_phone_region' => 'FR',\n);/g" /var/www/html/nextcloud/config/config.php
# Commande a faire après la config next cloud faite sur l'interface Web