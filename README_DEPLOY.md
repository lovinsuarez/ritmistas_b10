# Deploy Checklist — Ritmistas B10

Este documento descreve passos práticos para colocar o backend (FastAPI) e o frontend (Flutter) em produção, usando o Render como host. Inclui variáveis de ambiente necessárias, comandos de build e verificações pós-deploy.

---

## 1) Backend (FastAPI) — Render Service

- Requisitos no Render:
  - Crie um novo **Web Service** (Python) ou use o serviço existente.
  - Conecte o PostgreSQL (Render Postgres) e copie a `DATABASE_URL`.

- Variáveis de ambiente (Environment > Environment Variables):
  - `DATABASE_URL` — URL completa do Postgres (ex: `postgresql://user:pass@host:5432/dbname`).
  - `SECRET_KEY` — chave JWT forte (ex.: `openssl rand -hex 32`).
  - `DEV_ALLOW_INVITE` — NÃO definir em produção (se definido como `true` ativa rota dev que gera convites).
  - `PORT` — Render fornece automaticamente, não é necessário setar.

- Start Command (Render > Start Command):
  - `uvicorn main:app --host 0.0.0.0 --port $PORT`

- Build / Install (Render faz automaticamente durante deploy):
  - Garanta `requirements.txt` presente (já existe).

- Observações de segurança:
  - Nunca comite `SECRET_KEY` no repositório.
  - Não habilite `DEV_ALLOW_INVITE` em produção.

- Verificações pós-deploy:
  1. Abra `https://<your-service>.onrender.com/docs` — a UI do Swagger deve carregar.
  2. Teste `GET /users/me` (requer token) ou `POST /auth/token` com credenciais de teste.
  3. Verifique logs do serviço no Render para erros de DB/migrations.

## 2) Banco de dados

- O backend usa SQLAlchemy e `models.Base.metadata.create_all(bind=engine)` no startup; portanto, as tabelas serão criadas automaticamente quando o app conseguir conectar no Postgres.
- Se preferir usar migration (Alembic), adicione um pipeline de migração antes do start.

## 3) Google Sign-In / Firebase (produção)

- Android:
  - Registre o app no Console do Google / Firebase.
  - Baixe `google-services.json` e coloque na pasta `android/app/` antes do build.
  - Adicione as chaves SHA-1 / SHA-256 do app (play signing se for publicar)

- iOS:
  - Baixe `GoogleService-Info.plist` e adicione ao projeto Xcode (Runner).

- Web:
  - Configure OAuth clients no Console Google com o domínio e origem (ex.: `https://your-web-host`)
  - Inicialize Firebase na aplicação web se for usar o fluxo web.

## 4) Frontend (Flutter)

- Para builds que apontam para a API de produção, use `--dart-define`:
  - `flutter build web --dart-define=API_BASE_URL=https://ritmistas-api.onrender.com`
  - Para `flutter run` local apontando para backend remoto:
    - `flutter run --dart-define=API_BASE_URL=https://ritmistas-api.onrender.com`

- Observação: o código já lê `API_BASE_URL` com fallback para `https://ritmistas-api.onrender.com`.

- Docker builds: se usar o `Dockerfile` presente no repositório, confirme a imagem base do Flutter
  suporta a versão do Dart exigida pelas dependências. Se durante o build aparecer erro do tipo
  "The current Dart SDK version is X.Y.Z" relacionado a `google_sign_in`, atualize a imagem no
  `Dockerfile` para uma tag compatível (ex.: `instrumentisto/flutter:3.38.3`) ou ajuste a versão
  do pacote (`google_sign_in:^6.2.2`) no `pubspec.yaml` como fallback temporário.

## 5) Limpeza antes do deploy (recomendada)

- Remova rotas ou scripts de desenvolvimento (opcional):
  - Garanta que `DEV_ALLOW_INVITE` não esteja setado no ambiente de produção.
  - Remova/oculte `create_invite.py` ou documente que é apenas para dev.

- Rodar `flutter analyze` e corrigir warnings/erros importantes.

## 6) Testes básicos de aceitação (E2E)

1. Faça login via Google com uma conta de teste. Verifique que o backend receba a requisição `POST /auth/google` e retorne `access_token`.
2. Teste registro via `POST /auth/register/user` com um `invite_code` válido.
3. Ao criar um usuário via Google (com invite), verifique que o status esteja `PENDING` até aprovado pelo Admin Master.
4. Aprove usuários pendentes via `PUT /admin-master/approve-global/{user_id}` (necessita token Admin).

## 7) Checklist rápido de deploy

- [ ] Configurar `DATABASE_URL` no Render
- [ ] Configurar `SECRET_KEY` no Render
- [ ] Garantir `DEV_ALLOW_INVITE` não definido
- [ ] Deploy e verificação de `/docs`
- [ ] Teste de login Google e endpoints principais

## 8) Dicas para CI / automação (opcional)

- GitHub Actions ideias:
  - `flutter analyze` em PRs
  - `flutter test` (se tiver testes)
  - Job de deploy que faz build da web com `--dart-define=API_BASE_URL=...` e envia para host (ex.: Render static site) ou publica apps com Fastlane

## 9) Revertendo mudanças de desenvolvimento (rápido)

- Para reverter `API_BASE_URL` a prod, não é necessário alterar código: no build não passe `--dart-define` e o valor padrão será a URL de produção.
- Remover rota dev: garanta que `DEV_ALLOW_INVITE` não esteja setado no Render.

---

Se quiser, eu gero um arquivo `render-backend-setup.md` com passo-a-passo específico para a interface do Render (com screenshots/valores), ou crio um `GitHub Actions` workflow esqueleto que faz `flutter analyze` + `flutter build web` e deploy.
