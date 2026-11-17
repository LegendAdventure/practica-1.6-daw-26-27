#!/bin/bash
set -ex

# Importamos las variables de entorno
source .env

# Descargamos e instalamos WP-CLI
rm -f /tmp/wp-cli.phar
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp
chmod +x /tmp/wp-cli.phar
mv /tmp/wp-cli.phar /usr/local/bin/wp

# Limpiamos /var/www/html y creamos el subdirectorio wordpress
rm -rf /var/www/html/*
mkdir -p /var/www/html/wordpress

# Descargamos WordPress en su propio directorio (/var/www/html/wordpress)
wp core download --locale=es_ES --path=/var/www/html/wordpress --allow-root

# Creamos base de datos y usuario en MySQL
mysql -u root -e "DROP DATABASE IF EXISTS $DB_NAME"
mysql -u root -e "CREATE DATABASE $DB_NAME"
mysql -u root -e "DROP USER IF EXISTS '$DB_USER'@'$IP_CLIENTE_MYSQL'"
mysql -u root -e "CREATE USER '$DB_USER'@'$IP_CLIENTE_MYSQL' IDENTIFIED BY '$DB_PASSWORD'"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'$IP_CLIENTE_MYSQL'"
mysql -u root -e "FLUSH PRIVILEGES"

# Creamos wp-config.php dentro de /var/www/html/wordpress
wp config create \
  --dbname=$DB_NAME \
  --dbuser=$DB_USER \
  --dbpass=$DB_PASSWORD \
  --dbhost=$DB_HOST \
  --path=/var/www/html/wordpress \
  --allow-root

# Instalamos WordPress apuntando a /wordpress
wp core install \
  --url="https://$LETS_ENCRYPT_DOMAIN/wordpress" \
  --title="$WORDPRESS_TITLE" \
  --admin_user=$WORDPRESS_ADMIN_USER \
  --admin_password=$WORDPRESS_ADMIN_PASSWORD \
  --admin_email=$WORDPRESS_ADMIN_EMAIL \
  --path=/var/www/html/wordpress \
  --allow-root

# Configuramos WP_HOME en la raíz y WP_SITEURL en /wordpress
wp option update home "https://$LETS_ENCRYPT_DOMAIN" --path=/var/www/html/wordpress --allow-root
wp option update siteurl "https://$LETS_ENCRYPT_DOMAIN/wordpress" --path=/var/www/html/wordpress --allow-root

# Copiamos index.php a /var/www/html y modificamos la ruta de wp-blog-header.php
cp /var/www/html/wordpress/index.php /var/www/html/index.php
sed -i "s#wp-blog-header.php#wordpress/wp-blog-header.php#" /var/www/html/index.php

# Configuramos enlaces permanentes y .htaccess en la raíz
wp rewrite structure '/%postname%/' --path=/var/www/html/wordpress --allow-root
cp ../htaccess/.htaccess /var/www/html/.htaccess

# Instalamos y configuramos WPS Hide Login
wp plugin install wps-hide-login --activate --path=/var/www/html/wordpress --allow-root
wp option update whl_page $URL_HIDE_LOGIN --path=/var/www/html/wordpress --allow-root

# Asignamos permisos a todo /var/www/html
chown -R www-data:www-data /var/www/html