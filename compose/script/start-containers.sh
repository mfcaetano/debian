#!/bin/bash
set -e

echo "[+] Starting Nextcloud stack"
cd /home/mfcaetano/debian/compose/nextcloud
docker compose up -d

echo "[+] Starting Traefik"
cd /home/mfcaetano/debian/compose/traefik
docker compose up -d
