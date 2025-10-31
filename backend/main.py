# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\main.py
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import timedelta

# Importa tudo que criamos nos outros arquivos
import crud, models, schemas, security
from database import engine, get_db

# --- Criação das Tabelas no Banco ---
# Esta linha diz ao SQLAlchemy para criar todas as tabelas
# (baseado nos nossos 'models.py') no banco de dados do Render.
# (Só executa se as tabelas ainda não existirem)
models.Base.metadata.create_all(bind=engine)

# --- Inicialização do App FastAPI ---
app = FastAPI(
    title="Projeto Ritmistas B10 API",
    description="API para gerenciamento de presença e ranking."
)
origins = [
    "*", # O "*" permite TODAS as origens. É o mais simples para desenvolvimento.
    # Mais tarde, poderíamos restringir para:
    # "http://localhost",
    # "http://localhost:8080",
    # "http://localhost:5000", # Adicione a porta que o Flutter usar
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,       # Quais origens são permitidas
    allow_credentials=True,    # Permitir cookies (se usarmos)
    allow_methods=["*"],       # Quais métodos HTTP são permitidos (GET, POST, etc.)
    allow_headers=["*"],       # Quais cabeçalhos HTTP são permitidos
)

# --- Endpoints (Rotas da API) ---

@app.get("/")
def read_root():
    """Endpoint inicial apenas para testar se a API está online."""
    return {"status": "API Ritmistas B10 está online!"}


@app.post("/auth/register/admin", response_model=schemas.User)
def register_admin(admin_data: schemas.AdminCreate, db: Session = Depends(get_db)):
    """
    Endpoint para registrar o primeiro Administrador e seu Setor.
    """
    
    # 1. Verifica se o email já existe
    db_user = crud.get_user_by_email(db, email=admin_data.email)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email já registrado."
        )
    
    # 2. Chama a função do crud para criar o admin e o setor
    try:
        new_admin = crud.create_admin_and_sector(db=db, admin_data=admin_data)
        return new_admin
    except Exception as e:
        # Se algo der errado (ex: erro de banco), desfaz a transação
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao criar admin: {str(e)}"
        )

@app.post("/auth/token", response_model=schemas.Token)
def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(), 
    db: Session = Depends(get_db)
):
    """
    Endpoint de Login. Recebe email (no campo 'username') e senha.
    Retorna um Token JWT.
    """

    # 1. Busca o usuário pelo email (que vem no campo 'username' do formulário)
    user = crud.get_user_by_email(db, email=form_data.username)

    # 2. Verifica se o usuário existe E se a senha está correta
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou senha incorretos.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 3. Cria o token de acesso
    access_token_expires = timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )

    # 4. Retorna o token
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/redeem")
def redeem_code_endpoint(
    redeem_request: schemas.RedeemCodeRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user) # <-- ROTA PROTEGIDA!
):
    """
    Endpoint para um usuário resgatar um código (geral ou único).
    """

    # 1. Busca o código no banco
    code = crud.get_code_by_string(db, code_string=redeem_request.code_string)
    if not code:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Código não encontrado."
        )

    # 2. Tenta resgatar o código (a função do crud trata das regras)
    try:
        message = crud.redeem_code(db=db, user=current_user, code=code)

        # Verifica se a mensagem é de sucesso ou de erro de regra
        if "sucesso" not in message:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=message
            )

        return {"detail": message}

    except Exception as e:
        db.rollback()
        # Se for um HTTPException que já definimos, apenas o repasse
        if isinstance(e, HTTPException):
            raise e
        # Se for um erro inesperado
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro interno: {str(e)}"
        )

@app.post("/admin/codes/general", status_code=status.HTTP_201_CREATED)
def create_general_code_endpoint(
    code_data: schemas.CodeCreateGeneral,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_user)
):
    if current_admin.role != models.UserRole.admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Apenas admins podem criar códigos.")

    # TODO: verificar se o código já existe

    return crud.create_general_code(db=db, code_data=code_data, admin=current_admin)


@app.post("/admin/codes/unique", status_code=status.HTTP_201_CREATED)
def create_unique_code_endpoint(
    code_data: schemas.CodeCreateUnique,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_user)
):
    if current_admin.role != models.UserRole.admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Apenas admins podem criar códigos.")

    # TODO: verificar se o usuário a ser atribuído existe

    return crud.create_unique_code(db=db, code_data=code_data, admin=current_admin)

@app.post("/checkin")
def checkin_endpoint(
    checkin_request: schemas.CheckInRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user) # Rota protegida
):
    """
    Endpoint para um usuário fazer check-in (ler QRCode de atividade).
    """
    try:
        message = crud.create_checkin(
            db=db, 
            user=current_user, 
            activity_id=checkin_request.activity_id
        )

        if "sucesso" not in message:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=message
            )

        return {"detail": message}

    except Exception as e:
        db.rollback()
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro interno: {str(e)}"
        )
    
@app.get("/ranking", response_model=schemas.RankingResponse)
def get_ranking_endpoint(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user) # Rota protegida
):
    """
    Retorna o ranking completo do setor do usuário logado.
    """
    ranking_data = crud.get_sector_ranking(db=db, sector_id=current_user.sector_id)

    return {
        "my_user_id": current_user.user_id,
        "ranking": ranking_data
    }

@app.post("/auth/register/user", response_model=schemas.User, status_code=status.HTTP_201_CREATED)
def register_user(user_data: schemas.UserRegister, db: Session = Depends(get_db)):
    """
    Endpoint para um usuário normal se registrar usando um link de convite.
    """
    # Verifica se o email já existe
    db_user = crud.get_user_by_email(db, email=user_data.email)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email já registrado."
        )

    # Tenta criar o usuário
    new_user = crud.create_user_from_invite(db=db, user_data=user_data)

    if not new_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Código de convite inválido."
        )

    return new_user

@app.get("/admin/my-sector", response_model=schemas.SectorInfo)
def get_my_sector_info(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """Retorna as informações do setor do usuário logado."""

    # Esta rota pode ser usada por qualquer usuário, não apenas admin
    sector = crud.get_sector_by_id(db, sector_id=current_user.sector_id)
    if not sector:
         raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Setor não encontrado.")

    return sector

@app.get("/users/me", response_model=schemas.UserResponse) # <-- MUDANÇA AQUI
def read_users_me(
    db: Session = Depends(get_db), # <-- ADICIONA O db
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Retorna os dados do usuário atualmente logado.
    Se for admin, inclui o código de convite do setor.
    """
    invite_code = None
    
    # Se for admin, busca o código de convite do setor
    if current_user.role == models.UserRole.admin:
        sector = crud.get_sector_by_id(db=db, sector_id=current_user.sector_id)
        if sector:
            invite_code = sector.invite_code
            
    # Retorna o novo schema com todos os dados
    return schemas.UserResponse(
        user_id=current_user.user_id,
        username=current_user.username,
        email=current_user.email,
        role=current_user.role,
        sector_id=current_user.sector_id,
        invite_code=invite_code # <-- NOVO CAMPO
    )

@app.post("/admin/activities", status_code=status.HTTP_201_CREATED)
def create_activity_endpoint(
    activity_data: schemas.ActivityCreate,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_user)
):
    """Endpoint para um admin criar uma nova atividade."""

    if current_admin.role != models.UserRole.admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Apenas admins podem criar atividades.")

    try:
        activity = crud.create_activity(db=db, activity_data=activity_data, admin=current_admin)
        return activity
    except ValueError as e:
        # Captura a regra de negócio do 'address'
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Erro interno: {str(e)}")
    

@app.get("/admin/activities", response_model=list[schemas.Activity])
def get_activities_endpoint(
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_user)
):
    """Retorna todas as atividades do setor do admin logado."""

    if current_admin.role != models.UserRole.admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Apenas admins podem ver as atividades.")

    activities = crud.get_activities_by_sector(db=db, sector_id=current_admin.sector_id)
    return activities

@app.get("/admin/users", response_model=list[schemas.UserAdminView])
def get_users_endpoint(
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_user)
):
    """[Admin] Retorna todos os usuários do setor do admin."""
    if current_admin.role != models.UserRole.admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado.")

    return crud.get_users_by_sector(db=db, sector_id=current_admin.sector_id)


@app.put("/admin/users/{user_id}/promote", response_model=schemas.UserAdminView)
def promote_user_endpoint(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_user)
):
    """[Admin] Promove um usuário a admin."""
    if current_admin.role != models.UserRole.admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado.")

    user_to_promote = crud.get_user_by_id(db, user_id=user_id)

    if not user_to_promote or user_to_promote.sector_id != current_admin.sector_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado neste setor.")

    return crud.update_user_role(db=db, user_to_update=user_to_promote, new_role=models.UserRole.admin)


@app.delete("/admin/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user_endpoint(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_user)
):
    """[Admin] Deleta um usuário do setor."""
    if current_admin.role != models.UserRole.admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado.")

    if user_id == current_admin.user_id:
         raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Admin não pode deletar a si mesmo.")

    user_to_delete = crud.get_user_by_id(db, user_id=user_id)

    if not user_to_delete or user_to_delete.sector_id != current_admin.sector_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado neste setor.")

    crud.delete_user(db=db, user_to_delete=user_to_delete)
    return {"ok": True} # Retorno 204 não tem corpo

@app.get("/admin/users/{user_id}/dashboard", response_model=schemas.UserDashboard)
@app.get("/admin/users/{user_id}/dashboard", response_model=schemas.UserDashboard)
def get_user_dashboard_endpoint(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Retorna a dashboard detalhada de um usuário específico.
    Acesso permitido se:
    1. O requisitante é um Admin do mesmo setor.
    2. O requisitante é o próprio usuário (vendo seu dashboard).
    """
    
    # 1. Verifica se o usuário-alvo (user_id) existe
    target_user = crud.get_user_by_id(db, user_id=user_id)
    if not target_user:
         raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário alvo não encontrado.")

    # 2. Verifica se o requisitante (current_user) tem permissão
    is_admin = current_user.role == models.UserRole.admin
    is_self = current_user.user_id == user_id
    
    # Bloqueia se não for admin E não for ele mesmo
    if not is_admin and not is_self:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado.")
        
    # Bloqueia se não estiverem no mesmo setor
    if target_user.sector_id != current_user.sector_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Usuário não pertence ao seu setor.")

    # 3. Se passou, busca os dados
    dashboard_data = crud.get_user_dashboard_details(
        db=db, 
        user_id=user_id, 
        sector_id=current_user.sector_id
    )
    
    if not dashboard_data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Não foi possível carregar o dashboard.")
        
    return dashboard_data

@app.put("/admin/users/{user_id}/demote", response_model=schemas.UserAdminView)
def demote_user_endpoint(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_user)
):
    """[Admin] Rebaixa um admin para usuário."""
    if current_admin.role != models.UserRole.admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado.")
    
    if user_id == current_admin.user_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Admin não pode rebaixar a si mesmo.")

    user_to_demote = crud.get_user_by_id(db, user_id=user_id)
    
    if not user_to_demote or user_to_demote.sector_id != current_admin.sector_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado neste setor.")
        
    return crud.update_user_role(db=db, user_to_update=user_to_demote, new_role=models.UserRole.user)