# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\main.py
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from fastapi import FastAPI, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import List 

# Importa tudo que criamos nos outros arquivos
import crud, models, schemas, security
from database import engine, get_db

# --- Criação das Tabelas no Banco ---
# IMPORTANTE: Você precisará recriar seu banco de dados
# (apagar o .db local ou o banco no Render) para que
# a nova coluna 'status' seja adicionada.
models.Base.metadata.create_all(bind=engine)

# --- Inicialização do App FastAPI ---
app = FastAPI(
    title="Projeto Ritmistas B10 API",
    description="API para gerenciamento de presença e ranking."
)
origins = [
    "*", # O "*" permite TODAS as origens. É o mais simples para desenvolvimento.
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,      # Quais origens são permitidas
    allow_credentials=True,    # Permitir cookies (se usarmos)
    allow_methods=["*"],       # Quais métodos HTTP são permitidos (GET, POST, etc.)
    allow_headers=["*"],       # Quais cabeçalhos HTTP são permitidos
)

# --- Endpoints (Rotas da API) ---

# ============================================
# ENDPOINTS PÚBLICOS (Registro e Login)
# ============================================

@app.get("/")
def read_root():
    """Endpoint inicial apenas para testar se a API está online."""
    return {"status": "API Ritmistas B10 está online!"}


@app.post("/auth/register/admin-master", response_model=schemas.User)
def register_admin_master(admin_data: schemas.UserCreate, db: Session = Depends(get_db)):
    """
    Endpoint para registrar o primeiro Administrador Master (sem setor).
    """
    db_user = crud.get_user_by_email(db, email=admin_data.email)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email já registrado."
        )
    
    try:
        new_admin = crud.create_admin_master(db=db, admin_data=admin_data)
        return new_admin
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao criar admin: {str(e)}"
        )

@app.post("/auth/register/user", response_model=schemas.User, status_code=status.HTTP_201_CREATED)
def register_user(user_data: schemas.UserRegister, db: Session = Depends(get_db)):
    """
    Endpoint para um usuário normal se registrar usando um link de convite.
    O usuário será criado com status 'PENDING'.
    """
    db_user = crud.get_user_by_email(db, email=user_data.email)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email já registrado."
        )

    new_user = crud.create_user_from_invite(db=db, user_data=user_data)

    if not new_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Código de convite inválido."
        )

    return new_user

@app.post("/auth/token", response_model=schemas.Token)
def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(), 
    db: Session = Depends(get_db)
):
    """
    Endpoint de Login. Recebe email (no campo 'username') e senha.
    Retorna um Token JWT.
    """
    user = crud.get_user_by_email(db, email=form_data.username)

    if not user or not security.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou senha incorretos.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # NOVO: Verifica se a conta está ativa
    if user.status == models.UserStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Sua conta está pendente de aprovação pelo líder do setor."
        )

    access_token_expires = timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )

    return {"access_token": access_token, "token_type": "bearer"}

# ============================================
# ENDPOINTS DE USUÁRIO (Todos os papéis)
# ============================================

@app.get("/users/me", response_model=schemas.UserResponse)
def read_users_me(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """
    Retorna os dados do usuário atualmente logado.
    """
    invite_code = None
    
    if current_user.role in [models.UserRole.admin, models.UserRole.lider]:
        if current_user.sector_id:
            sector = crud.get_sector_by_id(db=db, sector_id=current_user.sector_id)
            if sector:
                invite_code = sector.invite_code
            
    # ALTERADO: Adiciona 'status' ao retorno
    return schemas.UserResponse(
        user_id=current_user.user_id,
        username=current_user.username,
        email=current_user.email,
        role=current_user.role,
        status=current_user.status, # <-- NOVO
        sector_id=current_user.sector_id,
        invite_code=invite_code
    )

@app.get("/users/my-sector", response_model=schemas.SectorInfo)
def get_my_sector_info(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """Retorna as informações do setor do usuário logado (Usuário ou Líder)."""
    if not current_user.sector_id:
         raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Este usuário não pertence a um setor.")

    sector = crud.get_sector_by_id(db, sector_id=current_user.sector_id)
    if not sector:
       raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Setor não encontrado.")

    return sector

# ============================================
# ENDPOINTS DE "USUARIO" (Função: user)
# ============================================

@app.post("/user/redeem")
def redeem_code_endpoint(
    redeem_request: schemas.RedeemCodeRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """ [Usuário] Endpoint para um usuário resgatar um código. """

    if current_user.role != models.UserRole.user:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Apenas usuários podem resgatar códigos.")

    code = crud.get_code_by_string(db, code_string=redeem_request.code_string)
    if not code:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Código não encontrado."
        )

    try:
        message = crud.redeem_code(db=db, user=current_user, code=code)
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

@app.post("/user/checkin")
def checkin_endpoint(
    checkin_request: schemas.CheckInRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """ [Usuário] Endpoint para um usuário fazer check-in. """

    if current_user.role != models.UserRole.user:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Apenas usuários podem fazer check-in.")

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

# ============================================
# ENDPOINTS DE RANKING (Todos os papéis)
# ============================================

@app.get("/ranking/sector", response_model=schemas.RankingResponse)
def get_sector_ranking_endpoint(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """ Retorna o ranking do setor do usuário logado (Usuário ou Líder). """
    
    if not current_user.sector_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Admin Master não possui ranking de setor. Use /ranking/geral."
        )
        
    ranking_data = crud.get_sector_ranking(db=db, sector_id=current_user.sector_id)
    return {
        "my_user_id": current_user.user_id,
        "ranking": ranking_data
    }

@app.get("/ranking/geral", response_model=schemas.RankingResponse)
def get_geral_ranking_endpoint(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(security.get_current_user)
):
    """ Retorna o ranking geral de todos os usuários (B10). """
    
    ranking_data = crud.get_geral_ranking(db=db)
    return {
        "my_user_id": current_user.user_id,
        "ranking": ranking_data
    }

# ============================================
# ENDPOINTS DE LÍDER (Líder e Admin Master)
# ============================================

@app.post("/lider/codes/general", status_code=status.HTTP_201_CREATED)
def create_general_code_endpoint(
    code_data: schemas.CodeCreateGeneral,
    db: Session = Depends(get_db),
    current_lider: models.User = Depends(security.get_current_lider) 
):
    """ [Líder] Cria um código de resgate geral para o seu setor. """
    
    if not current_lider.sector_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Usuário não está associado a um setor.")

    return crud.create_general_code(db=db, code_data=code_data, creator=current_lider)


@app.post("/lider/codes/unique", status_code=status.HTTP_201_CREATED)
def create_unique_code_endpoint(
    code_data: schemas.CodeCreateUnique,
    db: Session = Depends(get_db),
    current_lider: models.User = Depends(security.get_current_lider) 
):
    """ [Líder] Cria um código de resgate único para um usuário do seu setor. """

    if not current_lider.sector_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Usuário não está associado a um setor.")
        
    # TODO: verificar se o usuário a ser atribuído (code_data.assigned_user_id) 
    #       realmente pertence ao setor do líder (current_lider.sector_id)

    return crud.create_unique_code(db=db, code_data=code_data, creator=current_lider)

@app.post("/lider/activities", status_code=status.HTTP_201_CREATED)
def create_activity_endpoint(
    activity_data: schemas.ActivityCreate,
    db: Session = Depends(get_db),
    current_lider: models.User = Depends(security.get_current_lider) 
):
    """ [Líder] Cria uma nova atividade para o seu setor. """

    if not current_lider.sector_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Usuário não está associado a um setor.")

    try:
        activity = crud.create_activity(db=db, activity_data=activity_data, creator=current_lider)
        return activity
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Erro interno: {str(e)}")

@app.get("/lider/activities", response_model=List[schemas.Activity])
def get_activities_endpoint(
    db: Session = Depends(get_db),
    current_lider: models.User = Depends(security.get_current_lider) 
):
    """ [Líder] Retorna todas as atividades do seu setor. """
    
    if not current_lider.sector_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Usuário não está associado a um setor.")

    activities = crud.get_activities_by_sector(db=db, sector_id=current_lider.sector_id)
    return activities

@app.get("/lider/users", response_model=List[schemas.UserAdminView])
def get_users_endpoint(
    db: Session = Depends(get_db),
    current_lider: models.User = Depends(security.get_current_lider) 
):
    """ [Líder] Retorna todos os usuários ATIVOS do seu setor. """
    
    if not current_lider.sector_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Usuário não está associado a um setor.")

    return crud.get_users_by_sector(db=db, sector_id=current_lider.sector_id)

@app.delete("/lider/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user_endpoint(
    user_id: int,
    db: Session = Depends(get_db),
    current_lider: models.User = Depends(security.get_current_lider) 
):
    """ [Líder] Deleta um usuário ATIVO do seu setor. """
    
    if user_id == current_lider.user_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Líder não pode deletar a si mesmo.")

    user_to_delete = crud.get_user_by_id(db, user_id=user_id)

    if not user_to_delete or user_to_delete.sector_id != current_lider.sector_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado neste setor.")
        
    if user_to_delete.role != models.UserRole.user:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Líderes só podem deletar usuários.")
        
    # NOVO: Líder só pode deletar usuários ATIVOS (pendentes são em /reject-user)
    if user_to_delete.status != models.UserStatus.ACTIVE:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Este usuário não está ativo.")


    crud.delete_user(db=db, user_to_delete=user_to_delete)
    return {"ok": True} # Retorno 204 não tem corpo

@app.get("/lider/users/{user_id}/dashboard", response_model=schemas.UserDashboard)
def get_user_dashboard_endpoint(
    user_id: int,
    db: Session = Depends(get_db),
    current_lider: models.User = Depends(security.get_current_lider) 
):
    """
    [Líder] Retorna a dashboard detalhada de um usuário específico do seu setor.
    """
    
    target_user = crud.get_user_by_id(db, user_id=user_id)
    if not target_user:
         raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário alvo não encontrado.")

    is_lider_or_admin = current_lider.role in [models.UserRole.lider, models.UserRole.admin]
    is_self = current_user.user_id == user_id
    
    if not is_lider_or_admin and not is_self:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Acesso negado.")
        
    if target_user.sector_id != current_lider.sector_id:
        if current_lider.role != models.UserRole.admin:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Usuário não pertence ao seu setor.")

    dashboard_data = crud.get_user_dashboard_details(
        db=db, 
        user_id=user_id, 
        sector_id=target_user.sector_id 
    )
    
    if not dashboard_data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Não foi possível carregar o dashboard.")
        
    return dashboard_data

# --- NOVOS ENDPOINTS DE APROVAÇÃO DO LÍDER ---

@app.get("/lider/pending-users", response_model=List[schemas.UserAdminView])
def get_pending_users_endpoint(
    db: Session = Depends(get_db),
    current_lider: models.User = Depends(security.get_current_lider)
):
    """ [Líder] Retorna todos os usuários pendentes de aprovação do seu setor. """
    if not current_lider.sector_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Usuário não está associado a um setor.")
    return crud.get_pending_users_by_sector(db=db, sector_id=current_lider.sector_id)

@app.put("/lider/approve-user/{user_id}", response_model=schemas.UserAdminView)
def approve_user_endpoint(
    user_id: int,
    db: Session = Depends(get_db),
    current_lider: models.User = Depends(security.get_current_lider)
):
    """ [Líder] Aprova a entrada de um usuário pendente. """
    user_to_approve = crud.get_user_by_id(db, user_id=user_id)
    
    if not user_to_approve or user_to_approve.sector_id != current_lider.sector_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário pendente não encontrado neste setor.")
    if user_to_approve.status != models.UserStatus.PENDING:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Este usuário não está pendente.")
    
    return crud.update_user_status(db=db, user_to_update=user_to_approve, new_status=models.UserStatus.ACTIVE)

@app.delete("/lider/reject-user/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
def reject_user_endpoint(
    user_id: int,
    db: Session = Depends(get_db),
    current_lider: models.User = Depends(security.get_current_lider)
):
    """ [Líder] Rejeita (deleta) um usuário pendente. """
    user_to_reject = crud.get_user_by_id(db, user_id=user_id)
    
    if not user_to_reject or user_to_reject.sector_id != current_lider.sector_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário pendente não encontrado neste setor.")
    if user_to_reject.status != models.UserStatus.PENDING:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Este usuário não está pendente.")
    
    crud.delete_user(db=db, user_to_delete=user_to_reject)
    return {"ok": True}

# ============================================
# ENDPOINTS DE ADMIN MASTER (Admin Master)
# ============================================

@app.post("/admin-master/sectors", response_model=schemas.Sector)
def create_sector_endpoint(
    sector_name: str = Body(..., embed=True),
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_admin_master)
):
    """ [Admin Master] Cria um novo setor (organização). """
    return crud.create_sector(db=db, sector_name=sector_name)

@app.get("/admin-master/sectors", response_model=List[schemas.Sector])
def get_all_sectors_endpoint(
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_admin_master)
):
    """ [Admin Master] Lista todos os setores criados. """
    return crud.get_all_sectors(db=db)

@app.get("/admin-master/liders", response_model=List[schemas.UserAdminView])
def get_all_liders_endpoint(
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_admin_master)
):
    """ [Admin Master] Lista todos os usuários que são Líderes. """
    return crud.get_liders(db=db)

@app.put("/admin-master/users/{user_id}/promote-to-lider", response_model=schemas.UserAdminView)
def promote_user_to_lider_endpoint(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_admin_master) 
):
    """ [Admin Master] Promove um usuário (user) para Líder (lider). """
    
    user_to_promote = crud.get_user_by_id(db, user_id=user_id)

    if not user_to_promote:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado.")
        
    if user_to_promote.role != models.UserRole.user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Apenas usuários comuns podem ser promovidos a líder.")

    return crud.update_user_role(db=db, user_to_update=user_to_promote, new_role=models.UserRole.lider)

@app.put("/admin-master/liders/{lider_id}/demote-to-user", response_model=schemas.UserAdminView)
def demote_lider_to_user_endpoint(
    lider_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_admin_master) 
):
    """ [Admin Master] Rebaixa um Líder (lider) para Usuário (user). """
    
    if lider_id == current_admin.user_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Admin Master não pode rebaixar a si mesmo.")

    user_to_demote = crud.get_user_by_id(db, user_id=lider_id)
    
    if not user_to_demote:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuário não encontrado.")
    
    if user_to_demote.role != models.UserRole.lider:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Este usuário não é um líder.")
        
    return crud.update_user_role(db=db, user_to_update=user_to_demote, new_role=models.UserRole.user)

@app.put("/admin-master/sectors/{sector_id}/assign-lider", response_model=schemas.Sector)
def assign_lider_endpoint(
    sector_id: int,
    lider_id: int = Body(..., embed=True),
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_admin_master)
):
    """ [Admin Master] Designa um Líder (usuário com role 'lider') como o líder de um setor. """
    try:
        return crud.assign_lider_to_sector(db=db, lider_id=lider_id, sector_id=sector_id)
    except HTTPException as e:
        raise e
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")
    
@app.get("/admin-master/users", response_model=List[schemas.UserAdminView])
def get_all_users_endpoint(
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_admin_master)
):
    """ [Admin Master] Lista todos os usuários comuns (role 'user'). """
    return crud.get_all_users(db=db)

@app.get("/admin-master/sectors/{sector_id}/users", response_model=List[schemas.UserAdminView])
def get_sector_users_admin_endpoint(
    sector_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_admin_master)
):
    """ [Admin Master] Lista todos os usuários de um setor específico. """
    sector = crud.get_sector_by_id(db, sector_id=sector_id)
    if not sector:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Setor não encontrado.")
    
    return crud.get_users_by_sector(db=db, sector_id=sector_id)

@app.get("/admin-master/sectors/{sector_id}/ranking", response_model=schemas.RankingResponse)
def get_sector_ranking_admin_endpoint(
    sector_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(security.get_current_admin_master)
):
    """ [Admin Master] Retorna o ranking de um setor específico. """
    sector = crud.get_sector_by_id(db, sector_id=sector_id)
    if not sector:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Setor não encontrado.")

    ranking_data = crud.get_sector_ranking(db=db, sector_id=sector_id)
    return {
        "my_user_id": current_admin.user_id, 
        "ranking": ranking_data
    }