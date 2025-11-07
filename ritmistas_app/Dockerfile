# ESTÁGIO 1: Construir o App (Build Stage)
FROM cirrusci/flutter:latest as build

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos de dependência primeiro
# Isso otimiza o cache do Docker
COPY pubspec.yaml pubspec.lock ./

# Instala as dependências
RUN flutter pub get

# Agora copia apenas os diretórios necessários para o build
# Isso evita o conflito com o "lib" da imagem base
COPY lib/ ./lib/
COPY web/ ./web/
# Se você tiver uma pasta 'assets', descomente a linha abaixo
# COPY assets/ ./assets/

# Executa o comando de build do Flutter
RUN flutter build web --release

# ESTÁGIO 2: Servir o App (Serve Stage)
FROM nginx:alpine as final

# Copia APENAS os arquivos construídos do Estágio 1 para o servidor web
COPY --from=build /app/build/web /usr/share/nginx/html

# Expõe a porta 80 (padrão do Nginx)
EXPOSE 80