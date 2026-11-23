COMPOSE = docker compose -f srcs/docker-compose.yml
DATA    = /home/bgranier/data

all: up

up: secrets
		mkdir -p $(DATA)/mariadb $(DATA)/wordpress
		$(COMPOSE) up -d --build

down:
		$(COMPOSE) down

stop:
		$(COMPOSE) stop

start:
		$(COMPOSE) start

ps:
		$(COMPOSE) ps

logs:
		$(COMPOSE) logs -f

secrets:
		@mkdir -p secrets
		@[ -f secrets/db_password.txt ]      || openssl rand -hex 12 > secrets/db_password.txt
		@[ -f secrets/db_root_password.txt ] || openssl rand -hex 12 > secrets/db_root_password.txt
		@[ -f secrets/credentials.txt ]      || printf "WP_ADMIN_PASSWORD=%s\nWP_USER_PASSWORD=%s\n" \
				"$$(openssl rand -hex 12)" "$$(openssl rand -hex 12)" > secrets/credentials.txt
		@chmod 600 secrets/*.txt
		@echo "Secrets prets dans secrets/"

clean:
		$(COMPOSE) down -v --rmi all

fclean: clean
		sudo rm -rf $(DATA)

re: fclean all

.PHONY: all up down stop start ps logs clean fclean re secrets