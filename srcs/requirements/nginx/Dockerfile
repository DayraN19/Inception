FROM debian:bookworm

RUN apt update
RUN apt install nginx -y
RUN apt install vim -y
RUN mkdir -p /etc/nginx/ssl
RUN apt install openssl -y
RUN openssl req -x509 -nodes -out /etc/nginx/ssl/bgranier.crt -keyout /etc/nginx/ssl/bgranier.key -subj "/C=FR/ST=PAC/L=Nice/O=42/OU=42/CN=login.42.fr/UID=login"
COPY ./conf/nginx.conf /etc/nginx/conf.d
RUN mkdir -p /var/run/nginx
RUN chmod 755 /var/www/html
RUN chown -R www-data:www-data /var/www/html
EXPOSE	443

# Start nginx
CMD ["nginx", "-g", "daemon off;"]