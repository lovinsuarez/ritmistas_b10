# Usamos uma versão estável que funciona com as dependências acima
FROM instrumentisto/flutter:3.22.2 AS build

WORKDIR /app

# Copia configurações
COPY pubspec.yaml ./
# COPIE TAMBÉM O LOCKFILE PARA GARANTIR QUE ELE ESTEJA LÁ PARA SER DELETADO
COPY pubspec.lock ./

# Remove trava de versão do Windows
RUN rm pubspec.lock

# Baixa dependências
RUN flutter pub get

# Copia o código (SEM A PASTA ASSETS)
COPY lib/ ./lib/
COPY web/ ./web/

# Compila
RUN flutter build web --release --no-tree-shake-icons

# Servidor Nginx
FROM nginx:alpine as final
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80