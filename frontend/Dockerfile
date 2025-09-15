# frontend.Dockerfile
# Clona, builda a SPA e serve via Nginx.
# Também cria proxy /api -> http://api:4000 (mesmo domínio), inclusive WebSocket.

FROM node:20-alpine AS build
WORKDIR /src
RUN apk add --no-cache git
ARG GIT_REPO=https://github.com/gian0205/whaticketsaas.git
ARG GIT_REF=master

# URLs para o build do front (Vite/CRA). Ajuste se precisar.
ARG VITE_BACKEND_URL=/api
ARG REACT_APP_BACKEND_URL=/api
ENV VITE_BACKEND_URL=${VITE_BACKEND_URL}
ENV REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}

RUN git clone --depth=1 --branch ${GIT_REF} ${GIT_REPO} repo
WORKDIR /src/repo/frontend
RUN if [ -f package-lock.json ]; then \
      npm ci; \
    elif [ -f pnpm-lock.yaml ]; then \
      npm i -g corepack && corepack enable && pnpm i --frozen-lockfile=false; \
    elif [ -f yarn.lock ]; then \
      npm i -g yarn && (yarn install --frozen-lockfile || yarn install); \
    else \
      npm install --legacy-peer-deps; \
    fi
RUN npm run build
# Normaliza nome da pasta de build (dist ou build)
RUN if [ -d "dist" ]; then mv dist appbuild; elif [ -d "build" ]; then mv build appbuild; else echo "Pasta de build não encontrada"; exit 1; fi

FROM nginx:alpine
# Copia estáticos para o Nginx
COPY --from=build /src/repo/frontend/appbuild /usr/share/nginx/html

# Nginx com fallback SPA e proxy para API + WebSocket
RUN printf '\
server {\n\
  listen 80;\n\
  server_name _;\n\
  root /usr/share/nginx/html;\n\
  index index.html;\n\
  location / {\n\
    try_files $uri /index.html;\n\
  }\n\
  # Proxy API (ajuste porta se seu backend usar outra)\n\
  location /api/ {\n\
    proxy_pass http://api:4000/;\n\
    proxy_set_header Host $host;\n\
    proxy_set_header X-Real-IP $remote_addr;\n\
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
    proxy_set_header X-Forwarded-Proto $scheme;\n\
  }\n\
  # WebSocket (socket.io)\n\
  location /socket.io/ {\n\
    proxy_http_version 1.1;\n\
    proxy_set_header Upgrade $http_upgrade;\n\
    proxy_set_header Connection \"upgrade\";\n\
    proxy_pass http://api:4000/socket.io/;\n\
    proxy_set_header Host $host;\n\
    proxy_set_header X-Real-IP $remote_addr;\n\
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
    proxy_set_header X-Forwarded-Proto $scheme;\n\
  }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80
