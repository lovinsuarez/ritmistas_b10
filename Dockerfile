# ESTÁGIO 1: Construir o App (Build Stage)
# Usamos uma imagem que já tem o Flutter SDK
FROM cirrusci/flutter:stable as build

# Copia o código do seu projeto para dentro do container
COPY . .

# Executa o comando de build do Flutter
RUN flutter build web --release

# ESTÁGIO 2: Servir o App (Serve Stage)
# Usamos um servidor web leve (Nginx) para servir os arquivos estáticos
FROM nginx:alpine as final

# Copia APENAS os arquivos construídos do Estágio 1 para o servidor web
COPY --from=build /app/build/web /usr/share/nginx/html

# Expõe a porta 80 (padrão do Nginx)
EXPOSE 80