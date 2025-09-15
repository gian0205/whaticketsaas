# frontend.Dockerfile
FROM node:20-alpine AS build
WORKDIR /src
RUN apk add --no-cache git

ARG GIT_REPO=https://github.com/launcherbr/whaticketsaas.git
ARG GIT_REF=main
# API via mesmo domínio: /api
ARG VITE_BACKEND_URL=/api
ARG REACT_APP_BACKEND_URL=/api
ENV VITE_BACKEND_URL=${VITE_BACKEND_URL}
ENV REACT_APP_BACKEND_URL=${REACT_APP_BACKEND_URL}

RUN git clone --depth=1 --branch ${GIT_REF} ${GIT_REPO} repo
WORKDIR /src/repo/frontend
RUN npm ci
RUN npm run build
# Normaliza build dir
RUN if [ -d "build" ]; then mv build appbuild; elif [ -d "dist" ]; then mv dist appbuild; else echo "Pasta de build não encontrada"; exit 1; fi

FROM nginx:alpine
# Copia estáticos
COPY --from=build /src/repo/frontend/appbuild /usr/share/nginx/html

# Nginx com fallback SPA e proxy /api -> api:8080 + websocket
RUN printf '\
server {\n\
  listen 80;\n\
  server_name _;\n\
  root /usr/share/nginx/html;\n\
  index index.html;\n\
  location / {\n\
    try_files $uri /index.html;\n\
  }\n\
  location /api/ {\n\
    proxy_pass http://api:8080/;\n\
    proxy_set_header Host $host;\n\
    proxy_set_header X-Real-IP $remote_addr;\n\
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
    proxy_set_header X-Forwarded-Proto $scheme;\n\
  }\n\
  location /socket.io/ {\n\
    proxy_http_version 1.1;\n\
    proxy_set_header Upgrade $http_upgrade;\n\
    proxy_set_header Connection \"upgrade\";\n\
    proxy_pass http://api:8080/socket.io/;\n\
    proxy_set_header Host $host;\n\
    proxy_set_header X-Real-IP $remote_addr;\n\
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
    proxy_set_header X-Forwarded-Proto $scheme;\n\
  }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80
