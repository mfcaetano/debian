#!/usr/bin/env bash
set -e

# Diretório absoluto do projeto (independente de quem chamou o script)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$BASE_DIR"

echo "[+] Subindo volumes e redes"
docker compose -f volumes-networks.yml up -d

echo "[+] Subindo MariaDB"
docker compose -f mariadb/docker-compose.yml up -d

echo "[+] Subindo Nextcloud"
docker compose -f nextcloud/docker-compose.yml up -d

echo "[+] Subindo Traefik"
docker compose -f traefik/docker-compose.yml up -d

echo "[✓] Stack iniciada"

