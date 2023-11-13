#!/bin/bash
# Script para instalar wordpress en su propio directorio. 
# /var/www/html/wordpress
#Esto muestra todos los comandos que se van ejecutando
set -ex 
#Actualizamos los repositorios
apt update

#Actualizamos los paquetes de la máquina 

#apt upgrade -y

#Incluimos las variables del archivo .env

source .env

#Eliminamos instalaciones previas 

rm -rf /tmp/latest.zip

#Descargamos la última versión de WordPress con el comando wget.

wget http://wordpress.org/latest.zip -P /tmp


# Instalamos unzip 

sudo apt install unzip -y

#Ejecuto el comando zip para descomprimirlo.

unzip -u /tmp/latest.zip -d /tmp/

#Antes de mover el contenido eliminamos instalaciones previas de WordPress en /var/www/html

rm -rf /var/www/html/*

#Creamos la carpeta wordpress

mkdir -p /var/www/html/wordpress

#Movemos el contenido de /tmp/wordpress a /var/html

mv -f /tmp/wordpress/* /var/www/html/wordpress

# Creamos la base de datos y el usuario de base de datos.

mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

#Creamosnuestro archivo de configuración de WordPress.

cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php

# Modificamos los parámetros dentro del archivo wp-config.php

sed -i "s/database_name_here/$WORDPRESS_DB_NAME/" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/$WORDPRESS_DB_USER/" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/$WORDPRESS_DB_PASSWORD/" /var/www/html/wordpress/wp-config.php
sed -i "s/localhost/$WORDPRESS_DB_HOST/" /var/www/html/wordpress/wp-config.php

#Cambiamos los permisos para el usuario www-data:www-data.

chown -R www-data:www-data /var/www/html/wordpress


#Configuramos las variables WP_SITEURL y WP_HOME del archivo de configuración wp-config.php.

sed -i "/DB_COLLATE/a define('WP_SITEURL', 'https://$CERTIFICATE_DOMAIN/wordpress');" /var/www/html/wordpress/wp-config.php
sed -i "/WP_SITEURL/a define('WP_HOME', 'https://$CERTIFICATE_DOMAIN');" /var/www/html/wordpress/wp-config.php

# Copiamos el archivo /var/www/html/wordpress/index.php a /var/www/html

cp /var/www/html/wordpress/index.php /var/www/html

# Editamos el archivo index.php

sed -i "s#wp-blog-header.php#wordpress/wp-blog-header.php#" /var/www/html/index.php

# Copiamos el archivo .htacces
cp ../htaccess/.htaccess /var/www/html/
 

# Habilitamos el módulo mod_rewrite de Apache.

a2enmod rewrite

#Reiniciamos el apache2

sudo systemctl restart apache2