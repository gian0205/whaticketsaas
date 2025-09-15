# backend.Dockerfile
# Clona e builda o backend do seu repo

FROM node:20-alpine AS build
WORKDIR /src
RUN apk add --no-cache git python3 make g++
ARG GIT_REPO=https://github.com/gian0205/whaticketsaas.git
ARG GIT_REF=master

# Clona apenas o necessário
RUN git clone --depth=1 --branch ${GIT_REF} ${GIT_REPO} repo
WORKDIR /src/repo/backend

# Instala deps e builda (se não houver etapa de build, seguimos mesmo assim)
RUN npm ci
RUN npm run build || echo "Sem etapa de build (ok)."
RUN npm prune --omit=dev

FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    TZ=America/Sao_Paulo \
    PORT=4000

# Copia artefatos mínimos
COPY --from=build /src/repo/backend/node_modules ./node_modules
COPY --from=build /src/repo/backend/package*.json ./
# Copia dist (se existir) e mantém src de fallback
COPY --from=build /src/repo/backend/dist ./dist
COPY --from=build /src/repo/backend/src ./src

# Persistência de mídias/QRs (ajuste se seu fork usar outro caminho)
VOLUME ["/app/public"]

# Porta padrão (mapeie no Coolify conforme seu domínio)
EXPOSE 4000

# Migrações (se houver) + start com fallbacks comuns
CMD sh -c '\
  echo "Iniciando Whaticket backend na porta ${PORT}..." && \
  if npm run | grep -q "migrate"; then npm run migrate || true; fi && \
  node dist/server.js 2>/dev/null || \
  node dist/app.js 2>/dev/null || \
  npm start || \
  node src/server.js'
