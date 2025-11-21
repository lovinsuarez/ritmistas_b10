# ESTÁGIO 1: Construir o App (Build Stage)
# Usando a imagem compatível com suas dependências
FROM instrumentisto/flutter:3.22.2 AS build

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos de dependência
COPY pubspec.yaml ./

# Instala as dependências
RUN flutter pub get

# --- AQUI ESTÁ A CORREÇÃO ---
# Copia as pastas do código E os assets (imagens)
COPY lib/ ./lib/
COPY web/ ./web/
COPY assets/ ./assets/ 
# ----------------------------

# Executa o comando de build do Flutter
# Adicionei --no-tree-shake-icons para evitar erros de fontes de ícones
RUN flutter build web --release --no-tree-shake-icons

# ESTÁGIO 2: Servir o App (Serve Stage)
FROM nginx:alpine as final

# Copia APENAS os arquivos construídos do Estágio 1 para o servidor web
COPY --from=build /app/build/web /usr/share/nginx/html

# Copia a configuração do Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expõe a porta 80
EXPOSE 80