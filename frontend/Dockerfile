# frontend.Dockerfile (PATCH)
FROM node:18-alpine AS build
WORKDIR /src
RUN apk add --no-cache git

ARG GIT_REPO=https://github.com/gian0205/whaticketsaas.git
ARG GIT_REF=master

# API via mesmo domínio (proxy /api no Nginx)
ARG VITE_BACKEND_URL=/api
ARG REACT_APP_BACKEND_URL=/api
ENV VITE_BACKEND_URL=${VITE_BACKEND_URL}
ENV REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}

RUN git clone --depth=1 --branch ${GIT_REF} ${GIT_REPO} repo
WORKDIR /src/repo/frontend

# Evita travas de peer deps e lockfile desatualizado
ENV NPM_CONFIG_LEGACY_PEER_DEPS=true
RUN rm -f package-lock.json yarn.lock pnpm-lock.yaml \
 && npm install --legacy-peer-deps \
 && npm install --legacy-peer-deps material-ui-popup-state@^5

# (opcional, se CRA reclamar de warnings)
ENV CI=false

RUN npm run build
RUN if [ -d dist ]; then mv dist appbuild; elif [ -d build ]; then mv build appbuild; else echo "Pasta de build não encontrada"; exit 1; fi

FROM nginx:alpine
COPY --from=build /src/repo/frontend/appbuild /usr/share/nginx/html

# Proxy /api -> api:4000 + websocket (ajuste a porta se sua API for 8080)
RUN printf '\
server {\n\
  listen 80;\n\
  server_name _;\n\
  root /usr/share/nginx/html;\n\
  index index.html;\n\
  location / { try_files $uri /index.html; }\n\
  location /api/ { proxy_pass http://api:4000/; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; proxy_set_header X-Forwarded-Proto $scheme; }\n\
  location /socket.io/ { proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection \"upgrade\"; proxy_pass http://api:4000/socket.io/; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; proxy_set_header X-Forwarded-Proto $scheme; }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80
