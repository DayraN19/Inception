COMPOSE = docker compose -f srcs/docker-compose.yml
DATA    = /home/bgranier/data

all: up

up:
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

clean:
		$(COMPOSE) down -v --rmi all

fclean: clean
		sudo rm -rf $(DATA)

re: fclean all

.PHONY: all up down stop start ps logs clean fclean re