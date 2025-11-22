# Usamos uma versão mais recente do Flutter que suporta o Mobile Scanner 6.0+
FROM cirrusci/flutter:3.24.3 AS build

WORKDIR /app

# Copia os arquivos de configuração
COPY pubspec.yaml ./

# Remove o arquivo de trava de versão do Windows para não conflitar com o Linux
RUN rm -f pubspec.lock

# Instala dependências
RUN flutter pub get

# Copia o código (Note que removi a linha de assets para evitar aquele erro de arquivo não encontrado)
COPY lib/ ./lib/
COPY web/ ./web/

# Compila para web
RUN flutter build web --release --no-tree-shake-icons

# Servidor
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80