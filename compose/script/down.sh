#!/usr/bin/env bash
set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$BASE_DIR"

echo "[+] Parando Traefik"
docker compose -f traefik/docker-compose.yml down

echo "[+] Parando Nextcloud"
docker compose -f nextcloud/docker-compose.yml down

echo "[+] Parando MariaDB"
docker compose -f mariadb/docker-compose.yml down

echo "[+] Parando volumes/redes"
docker compose -f volumes-networks.yml down

echo "[✓] Stack parada"

