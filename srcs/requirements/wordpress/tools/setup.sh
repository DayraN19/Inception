#!/bin/sh
set -e

DB_PASS=$(cat /run/secrets/db_password)
. /run/secrets/credentials

if [ ! -f wp-config.php ]; then
    echo "Premier lancement : installation de WordPress..."

    wp core download --allow-root

    wp config create --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASS" \
        --dbhost=mariadb:3306

    wp core install --allow-root \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email

    wp user create --allow-root "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD"
fi

chown -R www-data:www-data /var/www/html

echo "Demarrage de php-fpm"
exec php-fpm8.2 -F