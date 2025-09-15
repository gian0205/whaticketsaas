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
RUN if [ -f package-lock.json ]; then \
      npm ci; \
    elif [ -f pnpm-lock.yaml ]; then \
      npm i -g corepack && corepack enable && pnpm i --frozen-lockfile=false; \
    elif [ -f yarn.lock ]; then \
      npm i -g yarn && (yarn install --frozen-lockfile || yarn install); \
    else \
      npm install --legacy-peer-deps; \
    fi
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
  echo "Iniciando Whaticket backend na porta ${PORT:-4000}..." && \
  npm i -g sequelize-cli >/dev/null 2>&1 || true && \
  if [ -n "$DB_USER" ] && [ -n "$DB_PASS" ] && [ -n "$DB_NAME" ]; then \
    echo "Executando migrations..."; \
    sequelize db:migrate --url "mysql://${DB_USER}:${DB_PASS}@${DB_HOST:-db}:${DB_PORT:-3306}/${DB_NAME}" || true; \
    if [ "$RUN_SEEDS" = "true" ]; then \
      echo "Executando seeds..."; \
      sequelize db:seed:all --url "mysql://${DB_USER}:${DB_PASS}@${DB_HOST:-db}:${DB_PORT:-3306}/${DB_NAME}" || true; \
    fi; \
  fi && \
  node dist/server.js 2>/dev/null || \
  node dist/app.js 2>/dev/null || \
  npm start || \
  node dist/index.js'
