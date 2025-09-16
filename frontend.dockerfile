# Usa uma imagem base do Node.js
FROM node:18-alpine

# Define o diretório de trabalho
WORKDIR /opt/app

# Copia o script de entrypoint que criamos para dentro da imagem
COPY entrypoint-web.sh /entrypoint-web.sh

# Dá permissão de execução para o script
RUN chmod +x /entrypoint-web.sh

# Define que o contêiner, ao iniciar, irá executar este script
ENTRYPOINT ["/entrypoint-web.sh"]
