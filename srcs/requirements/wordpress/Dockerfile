FROM debian:bookworm

RUN apt-get update && apt-get install -y \
                php8.2-fpm php8.2-mysql php8.2-cli curl mariadb-client \
        && rm -rf /var/lib/apt/lists/*

# WP-CLI : outil officiel pour installer WordPress en ligne de commande
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
        && chmod +x /usr/local/bin/wp

# php-fpm doit écouter sur le réseau (port 9000), pas sur un socket local
RUN sed -i 's|^listen = .*|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf \
        && sed -i 's|^error_log = .*|error_log = /proc/self/fd/2|' /etc/php/8.2/fpm/php-fpm.conf \
        && mkdir -p /run/php

COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["setup.sh"]