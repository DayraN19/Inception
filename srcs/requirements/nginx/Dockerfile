FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -f /etc/nginx/sites-enabled/default

RUN mkdir -p /etc/nginx/ssl \
	&& openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-out /etc/nginx/ssl/bgranier.crt -keyout /etc/nginx/ssl/bgranier.key \
	-subj "/C=FR/ST=PACA/L=Nice/O=42/OU=42/CN=bgranier.42.fr"

COPY ./conf/nginx.conf /etc/nginx/conf.d/

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
