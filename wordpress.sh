#!/bin/bash
# line from develop1
#line from devops junior

echo "127.0.0.1 wordpress.test.net www.wordpress.test.net" >> /etc/hosts

apt update

# variables file creation
cat <<EOF > env
WP_DOMAIN="wordpress.test.net"
WP_ADMIN_USERNAME="admin"
WP_ADMIN_PASSWORD="@admin123"
WP_ADMIN_EMAIL="no@spam.org"
WP_DB_NAME="wordpress"
WP_DB_USERNAME="wordpress"
WP_PATH="/var/www/wordpress"
WP_DB_PASSWORD="OySbciJ3S8KvEYo07Jr09NXBqesIWKqzUVot53EFEOnHramzWo1wjhDJftb3NsYj"  
MYSQL_ROOT_PASSWORD="SBPorLmM1a3UE60Kj9yStujbMTn2sITdZwkfx3ZJBW6rEXvd8K7RY0xNX3JkgTzh"
EOF

source ./env
. ./env


# mysql root access preparation
echo "mysql-server-5.7 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections


# hosting packages installation 
apt install -y nginx php php-fpm php-mysql php-curl php-gd mysql-server


# remove apache2 to avoid port conflict with nginx
apt remove -y apache2


# check php-fpm socket - check for avaliability (version for ubuntu 18)
ls /run/php/php7.2-fpm.sock


# configure MySQL
mysql -uroot -p$MYSQL_ROOT_PASSWORD<<EOFMYSQL
CREATE USER IF NOT EXISTS "$WP_DB_USERNAME"@"localhost" IDENTIFIED BY "$WP_DB_PASSWORD";
CREATE DATABASE IF NOT EXISTS $WP_DB_NAME;
GRANT ALL ON $WP_DB_NAME.* TO "$WP_DB_USERNAME"@"localhost";
EOFMYSQL


# confugure Nginx
mkdir -p $WP_PATH/public $WP_PATH/logs
cat <<EOF > /etc/nginx/sites-available/$WP_DOMAIN
server {
  listen 80;
  server_name $WP_DOMAIN www.$WP_DOMAIN;

  root $WP_PATH/public;
  index index.php;

  access_log $WP_PATH/logs/access.log;
  error_log $WP_PATH/logs/error.log;

  location / {
    try_files \$uri \$uri/ /index.php?\$args;
  }

  location ~ \.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php7.2-fpm.sock;
  }
}
EOF


ln -s /etc/nginx/sites-available/$WP_DOMAIN /etc/nginx/sites-enabled/$WP_DOMAIN
systemctl restart nginx


mkdir -p $WP_PATH/public/
chown -R $USER $WP_PATH/public/
cd $WP_PATH/public/


# install wordpress
wget https://wordpress.org/latest.tar.gz
tar xf latest.tar.gz --strip-components=1
rm latest.tar.gz

mv wp-config-sample.php wp-config.php
sed -i s/database_name_here/$WP_DB_NAME/ wp-config.php
sed -i s/username_here/$WP_DB_USERNAME/ wp-config.php
sed -i s/password_here/$WP_DB_PASSWORD/ wp-config.php
echo "define('FS_METHOD', 'direct');" >> wp-config.php


chown -R www-data:www-data $WP_PATH/public/
#curl - like silent installing
curl "http://$WP_DOMAIN/wp-admin/install.php?step=2" \
  --data-urlencode "weblog_title=$WP_DOMAIN"\
  --data-urlencode "user_name=$WP_ADMIN_USERNAME" \
  --data-urlencode "admin_email=$WP_ADMIN_EMAIL" \
  --data-urlencode "admin_password=$WP_ADMIN_PASSWORD" \
  --data-urlencode "admin_password2=$WP_ADMIN_PASSWORD" \
  --data-urlencode "pw_weak=1"

  # install wp-cli - important and must be  utility for functionality
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp


# install plugins and theme
for i in {user-switching,all-in-one-wp-security-and-firewall,cyr-and-lat,litespeed-cache,all-in-one-seo-pack,add-to-any,contact-form-7,easy-watermark,prodalet,visitors-traffic-real-time-statistics}; do wp plugin install $i --activate --path=/var/www/wordpress/public --allow-root; done
#installing custom theme
sudo -u $USER -i -- wp theme install hello-elementor --activate --path=/var/www/wordpress/public --allow-root


