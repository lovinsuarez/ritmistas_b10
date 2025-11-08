# ESTÁGIO 1: Construir o App (Build Stage)
# MUDANÇA FINAL: Usando a imagem 'instrumentisto' que TEM a tag de versão
FROM instrumentisto/flutter:3.22.2 AS build

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos de dependência
# (Não copiamos o .lock para forçar uma resolução limpa)
COPY pubspec.yaml ./

# Instala as dependências
RUN flutter pub get

# Agora copia o resto do código-fonte do app
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

# (Opcional, mas recomendado) Copia a configuração do Nginx
# Se você não tiver o nginx.conf, pode apagar esta linha
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expõe a porta 80 (padrão do Nginx)
EXPOSE 80