#!/bin/sh
set -e

echo "[api-entrypoint] Aguardando o banco de dados e o Redis..."
# (O depends_on do compose já cuida disso, mas é uma boa prática)

echo "[api-entrypoint] Executando migrações do banco de dados..."
DB_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
cd /app # Navega para o diretório da aplicação

# Encontra e executa as migrações
for MP in "/app/database/migrations" "/app/dist/database/migrations" "/app/src/database/migrations"; do
  if [ -d "$MP" ]; then
    echo "[api-entrypoint] Migrations encontradas em $MP...";
    npx sequelize-cli db:migrate --url "$DB_URL" --migrations-path "$MP" || true
    break
  fi
done

# Executa as seeds, se configurado
if [ "${RUN_SEEDS:-false}" = "true" ]; then
  for SP in "/app/database/seeders" "/app/dist/database/seeders" "/app/src/database/seeders"; do
    if [ -d "$SP" ]; then
      echo "[api-entrypoint] Seeds encontradas em $SP...";
      npx sequelize-cli db:seed:all --url "$DB_URL" --seeders-path "$SP" || true
      break
    fi
  done
fi

echo "[api-entrypoint] Migrações concluídas. Iniciando o servidor da API..."

# Executa o comando principal do contêiner (o que inicia o servidor Node.js)
exec "$@"
