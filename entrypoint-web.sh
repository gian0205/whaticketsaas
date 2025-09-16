#!/bin/sh
# Ativa o modo de falha rápida
set -e

# 1. Instala as dependências necessárias
echo "[web-entrypoint] Instalando dependências..."
apk add --no-cache git nginx netcat-openbsd

# 2. Clona o repositório e constrói o frontend
echo "[web-entrypoint] Clonando repositório e construindo o frontend..."
rm -rf /opt/app/src
git clone --depth=1 --branch master https://github.com/gian0205/whaticketsaas.git /opt/app/src
cd /opt/app/src/frontend
rm -f package-lock.json yarn.lock pnpm-lock.yaml || true
npm install --legacy-peer-deps
npm run build

# 3. Copia os arquivos estáticos para o Nginx
echo "[web-entrypoint] Publicando arquivos estáticos..."
BUILD_DIR=$( [ -d dist ] && echo dist || echo build )
rm -rf /usr/share/nginx/html/*
cp -r "$BUILD_DIR"/* /usr/share/nginx/html/

# 4. Detecta a porta da API
echo "[web-entrypoint] Aguardando e detectando a API..."
for p in 4000 8080 3000; do
  if nc -z api $p; then API_UP="http://api:$p"; break; fi
done
: ${API_UP:=http://api:4000}
echo "[web-entrypoint] API encontrada em: ${API_UP}"

# 5. Gera a configuração do Nginx dinamicamente
echo "[web-entrypoint] Gerando configuração do Nginx..."
cat > /etc/nginx/conf.d/default.conf <<NGINX
server {
  listen 80;
  server_name _;
  client_max_body_size 50m;
  root /usr/share/nginx/html;
  index index.html;

  location = /health { add_header Content-Type text/plain; return 200 "OK\n"; }
  location / { try_files \$uri /index.html; }

  location /api/ {
    proxy_pass ${API_UP}/;
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }

  location /socket.io/ {
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_pass ${API_UP}/socket.io/;
  }
}
NGINX

# 6. Inicia o Nginx
echo "[web-entrypoint] Iniciando Nginx..."
nginx -g "daemon off;"
