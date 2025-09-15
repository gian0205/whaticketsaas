# frontend.Dockerfile (FIX)
# Usa Node 18 para compat com libs antigas e ignora lockfile desatualizado
FROM node:18-alpine AS build
WORKDIR /src
RUN apk add --no-cache git

ARG GIT_REPO=https://github.com/gian0205/whaticketsaas.git
ARG GIT_REF=master

# Aponta o front para a API no mesmo domínio via /api
ARG VITE_BACKEND_URL=/api
ARG REACT_APP_BACKEND_URL=/api
ENV VITE_BACKEND_URL=${VITE_BACKEND_URL}
ENV REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}

RUN git clone --depth=1 --branch ${GIT_REF} ${GIT_REPO} repo
WORKDIR /src/repo/frontend

# 1) Evita travas de peer deps e ignora lockfile quebrado
ENV NPM_CONFIG_LEGACY_PEER_DEPS=true
RUN rm -f package-lock.json yarn.lock pnpm-lock.yaml \
 && npm install --legacy-peer-deps

# 2) Build
RUN npm run build
# Normaliza pasta de build
RUN if [ -d "dist" ]; then mv dist appbuild; elif [ -d "build" ]; then mv build appbuild; else echo "Pasta de build não encontrada"; exit 1; fi

FROM nginx:alpine
# Copia estáticos
COPY --from=build /src/repo/frontend/appbuild /usr/share/nginx/html

# Nginx com fallback SPA e proxy para API + WebSocket
RUN printf '\
server {\n\
  listen 80;\n\
  server_name _;\n\
  root /usr/share/nginx/html;\n\
  index index.html;\n\
  location / { try_files $uri /index.html; }\n\
  location /api/ {\n\
    proxy_pass http://api:4000/;\n\
    proxy_set_header Host $host;\n\
    proxy_set_header X-Real-IP $remote_addr;\n\
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
    proxy_set_header X-Forwarded-Proto $scheme;\n\
  }\n\
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
