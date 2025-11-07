# ESTÁGIO 1: Construir o App (Build Stage)
# MUDANÇA 1: Trocamos a imagem base para uma confiável
FROM fluttercommunity/flutter:3.19.0 as build

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos de dependência
COPY pubspec.yaml pubspec.lock ./

# MUDANÇA 2: Remove o lockfile para forçar uma resolução limpa.
# Isso corrige muitos erros silenciosos do 'pub get'.
RUN rm -f pubspec.lock

# Instala as dependências
RUN flutter pub get

# Agora copia apenas os diretórios necessários para o build
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