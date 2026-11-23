# User documentation

## Services provided

The stack hosts a WordPress website available at **https://bgranier.42.fr**.

| Service     | What it does |
|-------------|--------------|
| `nginx`     | Web server and only entry point (HTTPS on port 443, TLSv1.2/1.3). |
| `wordpress` | The WordPress website, executed by php-fpm. |
| `mariadb`   | The database storing articles, comments, users and settings. |

The site and its data are persistent: stopping or restarting the stack does not lose anything.

## Start and stop the project

From the root of the repository:

| Command       | Effect |
|---------------|--------|
| `make`        | Builds the images (if needed) and starts the stack. |
| `make stop`   | Stops the containers without removing them. |
| `make start`  | Starts the stopped containers again. |
| `make down`   | Stops and removes the containers. Data is kept. |
| `make re`     | Deletes everything (including data) and reinstalls from scratch. |

The first start takes a few minutes (images are built and WordPress is downloaded and installed).

## Access the website and the administration panel

1. Open **https://bgranier.42.fr** in a browser on the VM.
2. The certificate is self-signed: click *Advanced* then *Accept the risk and continue*.
3. The administration panel is at **https://bgranier.42.fr/wp-admin**.

Two WordPress accounts exist:

| Account | Role | Username defined in |
|---------|------|---------------------|
| Administrator | `administrator` | `WP_ADMIN_USER` in `srcs/.env` |
| Second user   | `author`        | `WP_USER` in `srcs/.env` |

Only HTTPS is available: `http://bgranier.42.fr` (port 80) is intentionally closed.

## Locate and manage credentials

All passwords are stored in the `secrets/` folder at the root of the repository. This folder is **never** committed to Git.

| File | Content |
|------|---------|
| `secrets/credentials.txt`      | `WP_ADMIN_PASSWORD=...` and `WP_USER_PASSWORD=...` (WordPress accounts) |
| `secrets/db_password.txt`      | Password of the database user used by WordPress |
| `secrets/db_root_password.txt` | Password of the MariaDB `root` user |

If these files are missing, `make` generates them with random passwords. Read them with `cat secrets/credentials.txt`.

Usernames, emails and the database name are in `srcs/.env`.

**Changing a password:** passwords are only applied at the first installation. After editing a file in `secrets/`, run `make re` to reinstall (this deletes the existing site content). A WordPress password can also be changed without reinstalling from *wp-admin → Users → Profile*.

## Check that the services are running

```sh
make ps
```
The three containers must be `Up`, and `mariadb` must show `(healthy)`.

```sh
make logs                     # live logs of all services (Ctrl+C to quit)
docker logs wordpress         # logs of one service
```
Expected at the end of the logs:
- `mariadb`: `ready for connections`
- `wordpress`: `NOTICE: ready to handle connections`

Quick HTTPS check:
```sh
curl -sk -o /dev/null -w "%{http_code}\n" https://bgranier.42.fr    # prints 200
```

If a container keeps restarting, read its logs with `docker logs <name>`.
