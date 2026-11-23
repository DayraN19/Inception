*This project has been created as part of the 42 curriculum by bgranier.*

# Inception

## Description

Inception is a system administration project: it sets up a small web infrastructure made of several services, each running in its own Docker container, orchestrated with Docker Compose inside a virtual machine.

The stack serves a WordPress website over HTTPS at `https://bgranier.42.fr`:

| Service     | Role                                                                 | Port (internal) |
|-------------|----------------------------------------------------------------------|-----------------|
| `nginx`     | Only entry point. Terminates TLS (TLSv1.2 / TLSv1.3 only), serves static files and forwards PHP requests to php-fpm. | 443 (published) |
| `wordpress` | WordPress + php-fpm. Executes the PHP code. Installed and configured automatically with WP-CLI. | 9000 |
| `mariadb`   | MariaDB database that stores the WordPress content and users.       | 3306 |

```
 Browser ──443/HTTPS──► nginx ──9000/FastCGI──► wordpress ──3306──► mariadb
                          │                        │                   │
                          └──── volume wordpress ──┘           volume mariadb
                                /home/bgranier/data/wordpress   /home/bgranier/data/mariadb
```

## Instructions

### Prerequisites

- A Linux virtual machine (Debian) with **Docker Engine** and the **Docker Compose plugin** installed.
- `make` and `sudo`.
- The domain pointing to the local machine:
  ```sh
  echo "127.0.0.1 bgranier.42.fr" | sudo tee -a /etc/hosts
  ```

### Configuration

Secrets are **not** stored in the Git repository. Create them before the first launch:

```sh
mkdir -p secrets
echo "your_db_password"      > secrets/db_password.txt
echo "your_db_root_password" > secrets/db_root_password.txt
printf "WP_ADMIN_PASSWORD=your_admin_password\nWP_USER_PASSWORD=your_user_password\n" > secrets/credentials.txt
```

Non-sensitive configuration lives in `srcs/.env` (domain name, database name and user, WordPress usernames and emails). See [DEV_DOC.md](DEV_DOC.md) for its full content.

### Build and run

```sh
make          # creates /home/bgranier/data, builds the images and starts the containers
make down     # stops and removes the containers (data is kept)
make fclean   # removes containers, images, volumes and all data
make re       # full rebuild from scratch
```

Then open `https://bgranier.42.fr` (the certificate is self-signed, accept the browser warning). The administration panel is at `https://bgranier.42.fr/wp-admin`.

More details: [USER_DOC.md](USER_DOC.md) (usage) and [DEV_DOC.md](DEV_DOC.md) (development).

## Project description

### Use of Docker and sources included

Each service has its own Dockerfile, written from scratch on top of `debian:bookworm` (the penultimate stable Debian release). No ready-made image is pulled from Docker Hub. The images are built by `docker compose`, called from the `Makefile`.

```
.
├── Makefile
├── secrets/                     # passwords (ignored by git)
└── srcs/
    ├── .env                     # non-sensitive configuration
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/               # Dockerfile + conf/nginx.conf
        ├── mariadb/             # Dockerfile + conf/50-server.cnf + tools/init.sh
        └── wordpress/           # Dockerfile + tools/setup.sh
```

### Main design choices

- **One process per container, running as PID 1.** Each entrypoint script ends with `exec`, so the real daemon (`nginx -g "daemon off;"`, `mysqld`, `php-fpm8.2 -F`) replaces the shell, runs in the foreground and receives Docker's stop signals directly. No `tail -f`, `sleep infinity` or infinite loop is used.
- **First-run initialisation only.** `init.sh` creates the database and users only if the database directory does not exist yet; `setup.sh` installs WordPress only if `wp-config.php` is missing. Restarts reuse the existing data.
- **Start-up order with a healthcheck.** MariaDB has a healthcheck (`mysqladmin ping`); WordPress uses `depends_on: condition: service_healthy`, so it never tries to connect before the database is ready.
- **TLS generated at build time.** nginx uses a self-signed certificate created with `openssl` during the image build; no key or certificate is stored in Git.
- **Automatic restart.** Every service uses `restart: unless-stopped`.
- **WP-CLI** installs and configures WordPress non-interactively (download, `wp-config.php`, site install, administrator and second user).

### Virtual Machines vs Docker

A **virtual machine** emulates a full computer: it runs its own kernel on virtualised hardware through a hypervisor. It offers strong isolation but is heavy (several GB, boots in minutes).
A **Docker container** is an isolated process that shares the host's kernel. Isolation comes from Linux namespaces (processes, network, filesystem) and cgroups (resource limits). Containers are light, start in seconds and are built from layered, reproducible images.
In this project both are used: the containers run inside a VM, which isolates the whole infrastructure from the school computer.

### Secrets vs Environment Variables

**Environment variables** are convenient for configuration, but they are visible with `docker inspect`, inherited by every child process and can leak into logs.
**Docker secrets** are mounted as read-only files in `/run/secrets/` and only in the containers that declare them. They are not part of the image nor of the container's environment.
Here, non-sensitive values (domain, usernames, database name) are in `srcs/.env`, while every password is a secret read from `/run/secrets/` by the entrypoint scripts. `nginx` receives no secret at all.

### Docker Network vs Host Network

With `network: host`, a container shares the host's network stack: no isolation, every port it opens is open on the host, and port conflicts are possible.
A **Docker bridge network** is a private virtual network: containers talk to each other by name thanks to Docker's internal DNS (`mariadb`, `wordpress`), and nothing is reachable from outside unless explicitly published.
Here the three containers share the `inception` bridge network and only nginx publishes a port (`443`). MariaDB and php-fpm are unreachable from the outside.

### Docker Volumes vs Bind Mounts

A **bind mount** maps an arbitrary host path into a container. It depends on the host's directory layout and is not managed by Docker.
A **named volume** is a Docker-managed resource with a name: it is listed by `docker volume ls`, can be inspected, shared between containers and removed with Docker commands.
Here two named volumes are used, `mariadb` (database files) and `wordpress` (website files, shared by `wordpress` and `nginx`). As required, the `local` driver is configured with `driver_opts` so that their data is stored in `/home/bgranier/data` on the host. They remain named volumes, not bind mounts.

## Resources

- Docker documentation: https://docs.docker.com/
- Dockerfile best practices: https://docs.docker.com/build/building/best-practices/
- Compose file reference: https://docs.docker.com/reference/compose-file/
- Secrets in Compose: https://docs.docker.com/compose/how-tos/use-secrets/
- Volumes: https://docs.docker.com/engine/storage/volumes/
- Networking: https://docs.docker.com/engine/network/
- NGINX SSL module: https://nginx.org/en/docs/http/ngx_http_ssl_module.html
- NGINX FastCGI module: https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- PHP-FPM configuration: https://www.php.net/manual/en/install.fpm.configuration.php
- WP-CLI commands: https://developer.wordpress.org/cli/commands/

### Use of AI

An AI assistant (Claude) was used as a learning and review tool:

- explaining Docker concepts (PID 1, `exec`, named volumes, secrets, healthchecks) and the subject's requirements;
- reviewing the Dockerfiles and configuration files and pointing out mistakes (certificate CN, image layers, secrets tracked by Git);
- providing step-by-step guides and commented skeletons for the MariaDB and WordPress setup, the `docker-compose.yml` and the `Makefile`;
- helping set up the virtual machine and debug issues (SSH port forwarding, Docker group permissions, php-fpm logs);
- drafting this documentation.

Every file was rewritten, tested in the VM and is understood by the author.
