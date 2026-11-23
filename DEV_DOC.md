# Developer documentation

## Set up the environment from scratch

### Prerequisites

- A Debian virtual machine with a user named `bgranier` (the data path is `/home/bgranier/data`).
- Docker Engine and the Docker Compose plugin:
  ```sh
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  echo "deb [signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list
  sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin make git
  sudo usermod -aG docker bgranier     # then log out and back in
  ```
- The domain name resolved locally:
  ```sh
  echo "127.0.0.1 bgranier.42.fr" | sudo tee -a /etc/hosts
  ```

### Configuration files

**`srcs/.env`**: non-sensitive variables passed to the containers with `env_file`:

```
DOMAIN_NAME=bgranier.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
WP_TITLE=Inception
WP_ADMIN_USER=bgranier          # must not contain "admin"
WP_ADMIN_EMAIL=bgranier@student.42nice.fr
WP_USER=editor1
WP_USER_EMAIL=editor1@example.com
```

**`secrets/`**: passwords, ignored by Git, mounted in `/run/secrets/` by Compose:

| File | Mounted as | Used by |
|------|-----------|---------|
| `db_password.txt`      | `/run/secrets/db_password`      | mariadb, wordpress |
| `db_root_password.txt` | `/run/secrets/db_root_password` | mariadb |
| `credentials.txt`      | `/run/secrets/credentials`      | wordpress |

`make secrets` (also run by `make`) creates any missing file with random passwords (`openssl rand -hex 12`). Existing files are never overwritten, since passwords are only applied at the first installation.

`credentials.txt` is sourced by a shell script, so it must contain plain `KEY=value` lines without spaces:
```
WP_ADMIN_PASSWORD=...
WP_USER_PASSWORD=...
```
Avoid shell special characters (`$`, `` ` ``, `"`, `'`, `\`, `!`, spaces) in all passwords.

## Build and launch

```sh
make
```
This runs:
1. `mkdir -p /home/bgranier/data/mariadb /home/bgranier/data/wordpress` (the volumes' storage must exist before Compose starts);
2. `docker compose -f srcs/docker-compose.yml up -d --build`.

Start-up sequence:
1. `mariadb` starts; on first run `init.sh` initialises the data directory, creates the database, the WordPress user and sets the root password (`mysqld --bootstrap`), then `exec mysqld`.
2. Once its healthcheck (`mysqladmin ping`) passes, `wordpress` starts; on first run `setup.sh` uses WP-CLI to download WordPress, create `wp-config.php`, install the site and create both users, then `exec php-fpm8.2 -F`.
3. `nginx` starts and listens on 443.

### Makefile rules

| Rule     | Command |
|----------|---------|
| `secrets` | create `secrets/` and generate random passwords for missing files (never overwrites) |
| `all` / `up` | `secrets` + create data dirs + `docker compose up -d --build` |
| `down`   | `docker compose down` (containers and network removed, data kept) |
| `stop` / `start` | stop / start the containers without removing them |
| `ps`     | `docker compose ps` |
| `logs`   | `docker compose logs -f` |
| `clean`  | `docker compose down -v --rmi all` (also removes volumes and images) |
| `fclean` | `clean` + `sudo rm -rf /home/bgranier/data` |
| `re`     | `fclean` then `all` |

## Manage containers and volumes

```sh
docker compose -f srcs/docker-compose.yml config   # validate the compose file (prints .env values!)
docker ps                                           # running containers
docker logs -f <service>                            # logs of a service
docker exec -it <service> sh                        # shell inside a container
docker exec -it mariadb mysql -u root -p            # MariaDB console
docker exec wordpress wp user list --allow-root     # WordPress users
docker top wordpress                                # processes (php-fpm master is PID 1)

docker network ls                                   # inception_inception
docker network inspect inception_inception          # containers on the network
docker volume ls                                    # inception_mariadb, inception_wordpress
docker volume inspect inception_wordpress           # shows device: /home/bgranier/data/wordpress
```

Rebuild a single service after editing its files:
```sh
docker compose -f srcs/docker-compose.yml up -d --build wordpress
```

Note: initialisation scripts only run when the data is empty. After changing `init.sh`, `setup.sh`, the `.env` or the secrets, run `make re` to apply the changes.

## Where data is stored and how it persists

| Volume | Mounted in | Host directory | Content |
|--------|-----------|----------------|---------|
| `mariadb`   | `mariadb:/var/lib/mysql`        | `/home/bgranier/data/mariadb`   | database files |
| `wordpress` | `wordpress:/var/www/html` and `nginx:/var/www/html` | `/home/bgranier/data/wordpress` | WordPress files, `wp-config.php`, uploads |

Both are **named volumes** using the `local` driver with `driver_opts` (`type: none`, `o: bind`, `device: ...`), so Docker manages them by name while their data lives in `/home/bgranier/data`.

Persistence:
- `make down` / `make` or a container crash: data is kept, nothing is reinstalled.
- `make clean`: Docker volumes are removed, but the files in `/home/bgranier/data` remain.
- `make fclean` / `make re`: the data directory is deleted; the next start reinstalls everything.

Files in `/home/bgranier/data` belong to the containers' users (`mysql`, `www-data`), which is why `fclean` needs `sudo`.
