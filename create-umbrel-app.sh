#!/usr/bin/env bash

set -euo pipefail

# Prefixo da loja (ajuste se mudar o nome da sua store)
APP_STORE_PREFIX="salesawagner"

if [ $# -lt 1 ]; then
  echo "Uso: $0 <nome-app-sem-prefixo> (ex.: $0 radarr)"
  exit 1
fi

APP_NAME_RAW="$1"                           # ex.: radarr
APP_NAME_LOWER="$(echo "$APP_NAME_RAW" | tr '[:upper:]' '[:lower:]')"
APP_NAME_CAPITALIZED="$(echo "${APP_NAME_LOWER:0:1}" | tr '[:lower:]' '[:upper:]')${APP_NAME_LOWER:1}"
APP_ID="${APP_STORE_PREFIX}-${APP_NAME_LOWER}"   # ex.: salesawagner-radarr
APP_DIR="${APP_ID}"

echo "Criando app '${APP_ID}' na pasta '${APP_DIR}'..."

# Pergunta dados básicos
read -rp "Porta Web UI do ${APP_NAME_LOWER} (ex.: 7878 para Radarr, 8989 para Sonarr): " APP_PORT
read -rp "Imagem Docker (ghcr.io/...) para o ${APP_NAME_LOWER}: " APP_IMAGE

# Cria pasta
mkdir -p "${APP_DIR}"

########################################
# umbrel-app.yml
########################################
cat > "${APP_DIR}/umbrel-app.yml" <<EOF
manifestVersion: 1
id: ${APP_ID}
category: media
name: ${APP_NAME_CAPITALIZED}
version: "1.0"
tagline: ${APP_NAME_CAPITALIZED} app
description: >
  ${APP_NAME_CAPITALIZED} integrado ao seu stack *arr, rodando na Umbrel.
developer: ${APP_NAME_CAPITALIZED}
website: https://example.com/${APP_NAME_LOWER}
submitter: ${APP_STORE_PREFIX}
submission: https://github.com/${APP_STORE_PREFIX}/${APP_STORE_PREFIX}-umbrel-store
repo: https://github.com/example/${APP_NAME_LOWER}
support: https://github.com/example/${APP_NAME_LOWER}/issues
icon: https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/${APP_NAME_LOWER}.png
port: ${APP_PORT}
gallery: []
path: ""
defaultUsername: ""
defaultPassword: ""
torrentPorts: []
EOF

########################################
# docker-compose.yml
########################################
cat > "${APP_DIR}/docker-compose.yml" <<EOF
services:
  app_proxy:
    environment:
      APP_HOST: ${APP_NAME_LOWER}_server_1
      APP_PORT: ${APP_PORT}
      PROXY_AUTH_WHITELIST: /api/*
    container_name: ${APP_NAME_LOWER}_app_proxy_1
    restart: unless-stopped

  server:
    image: ${APP_IMAGE}
    container_name: ${APP_NAME_LOWER}_server_1
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=America/Sao_Paulo
      - WEBUI_PORTS=${APP_PORT}/tcp
    volumes:
      - \${APP_DATA_DIR}/data/config:/config
      - /mnt/downloads:/downloads
      - /mnt/media/media:/media
    restart: unless-stopped

  mac:
    image: >-
      getumbrel/media-app-configurator:v1.3.0@sha256:67e75dd9f5a14402b7816119a8e20189bc2465484cea077909d164687e59742b
    user: '1000:1000'
    restart: on-failure
    volumes:
      - \${APP_DATA_DIR}/data/config:/config
    environment:
      APP_ID: ${APP_ID}
      # URL interna do próprio app dentro da rede Docker
      APP_URL: http://${APP_NAME_LOWER}_server_1:${APP_PORT}
      # URLs padrão do stack *arr que o configurador usa
      RADARR_URL: http://radarr_server_1:7878
      RADARR_CONFIG_XML: \${APP_PROWLARR_RADARR_CONFIG_XML}
      SONARR_URL: http://sonarr_server_1:8989
      SONARR_CONFIG_XML: \${APP_PROWLARR_SONARR_CONFIG_XML}
    container_name: ${APP_ID}_mac_1
EOF

echo "Arquivos criados em '${APP_DIR}':"
echo "  - umbrel-app.yml"
echo "  - docker-compose.yml"
echo "Agora ajuste as informações específicas do app (descrição, website, repo, icon, etc.) se quiser."

# ./create-umbrel-app.sh sonarr
# ./create-umbrel-app.sh prowlarr
# ./create-umbrel-app.sh whisparr
# ./create-umbrel-app.sh qbittorrent
# ./create-umbrel-app.sh sabnzbd
# ./create-umbrel-app.sh plex
# ./create-umbrel-app.sh flaresolverr
# ./create-umbrel-app.sh seerr