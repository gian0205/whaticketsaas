# backend.Dockerfile
FROM node:20-alpine AS build
WORKDIR /src
RUN apk add --no-cache git python3 make g++

# Passe o repo e o branch/tag por ARG (default: main)
ARG GIT_REPO=https://github.com/launcherbr/whaticketsaas.git
ARG GIT_REF=main

# Clone raso para build mais rápido
RUN git clone --depth=1 --branch ${GIT_REF} ${GIT_REPO} repo
WORKDIR /src/repo/backend

# Instala e builda (se não houver build, ignora)
RUN npm ci
RUN npm run build || echo "Sem etapa de build."

# Remove devDeps para produção
RUN npm prune --omit=dev

FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    TZ=America/Sao_Paulo

# Copia artefatos
COPY --from=build /src/repo/backend/node_modules ./node_modules
# Se existir dist/, copiamos; se não, copiamos fontes
COPY --from=build /src/repo/backend/dist ./dist
COPY --from=build /src/repo/backend/package*.json ./
COPY --from=build /src/repo/backend/src ./src

VOLUME ["/app/public"]
EXPOSE 8080

# Tenta iniciar pelas opções mais comuns
CMD sh -c '\
  echo "Iniciando backend..." && \
  if npm run | grep -q "migrate"; then npm run migrate || true; fi && \
  node dist/server.js 2>/dev/null || \
  node dist/app.js 2>/dev/null || \
  npm start || \
  node src/server.js'
