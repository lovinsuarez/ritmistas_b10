# ESTÁGIO 1: Construir o App (Build Stage)
# Usando a imagem compatível
FROM instrumentisto/flutter:3.22.2 AS build

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos de dependência
COPY pubspec.yaml pubspec.lock ./

# --- A CORREÇÃO MÁGICA ---
# Apaga o arquivo de bloqueio do Windows para o Linux calcular o dele
RUN rm -f pubspec.lock
# -------------------------

# Instala as dependências (agora ele vai achar as versões compatíveis sozinho)
RUN flutter pub get

# Copia o resto do código e os assets
COPY lib/ ./lib/
COPY web/ ./web/
COPY assets/ ./assets/

# Executa o comando de build
RUN flutter build web --release --no-tree-shake-icons

# ESTÁGIO 2: Servir o App (Serve Stage)
FROM nginx:alpine as final

# Copia os arquivos construídos
COPY --from=build /app/build/web /usr/share/nginx/html

# Copia a configuração do Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expõe a porta 80
EXPOSE 80