# backend/main.py
from fastapi import FastAPI, Depends, HTTPException, status, Body
from fastapi.responses import StreamingResponse # IMPORTANTE PARA O DOWNLOAD
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import List
import io

import crud, models, schemas, security
from database import engine, get_db

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Projeto Ritmistas B10 API")

origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- AUTH ---
@app.post("/auth/register/admin-master", response_model=schemas.User)
def register_admin_master(admin_data: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_email(db, email=admin_data.email)
    if db_user: raise HTTPException(status_code=400, detail="Email já registrado.")
    return crud.create_admin_master(db=db, admin_data=admin_data)

@app.post("/auth/register/user", response_model=schemas.User, status_code=201)
def register_user(user_data: schemas.UserRegister, db: Session = Depends(get_db)):
    db_user = crud.get_user_by_email(db, email=user_data.email)
    if db_user: raise HTTPException(status_code=400, detail="Email já registrado.")
    new_user = crud.create_user_from_invite(db=db, user_data=user_data)
    if not new_user: raise HTTPException(status_code=400, detail="Código inválido.")
    return new_user

@app.post("/auth/token", response_model=schemas.Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = crud.get_user_by_email(db, email=form_data.username)
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Email ou senha incorretos.")
    if user.status == models.UserStatus.PENDING:
        raise HTTPException(status_code=403, detail="Conta pendente de aprovação.")
    
    access_token = security.create_access_token(data={"sub": user.email}, expires_delta=timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES))
    return {"access_token": access_token, "token_type": "bearer"}

# --- USER ---
@app.get("/users/me", response_model=schemas.User) # Retorna o modelo completo com pontos
def read_users_me(db: Session = Depends(get_db), current_user: models.User = Depends(security.get_current_user)):
    # Preenche os pontos antes de retornar
    points_data, total = crud.get_user_points_breakdown(db, current_user)
    current_user.points_by_sector = points_data
    current_user.total_global_points = total
    return current_user

@app.post("/user/join-sector")
def join_sector(invite_code: schemas.JoinSectorRequest, db: Session = Depends(get_db), current_user: models.User = Depends(security.get_current_user)):
    """Permite ao usuário entrar em mais um setor usando um código."""
    msg = crud.join_sector(db, current_user, invite_code.invite_code)
    return {"detail": msg}

@app.post("/user/checkin")
def checkin(req: schemas.CheckInRequest, db: Session = Depends(get_db), current_user: models.User = Depends(security.get_current_user)):
    return {"detail": crud.create_checkin(db, current_user, req.activity_id)}

@app.post("/user/redeem")
def redeem(req: schemas.RedeemCodeRequest, db: Session = Depends(get_db), current_user: models.User = Depends(security.get_current_user)):
    code = crud.get_code_by_string(db, req.code_string)
    if not code: raise HTTPException(status_code=404, detail="Código não encontrado.")
    return {"detail": crud.redeem_code(db, current_user, code)}

# --- RANKING ---
@app.get("/ranking/geral", response_model=schemas.RankingResponse)
def ranking_geral(db: Session = Depends(get_db), current_user: models.User = Depends(security.get_current_user)):
    return {"ranking": crud.get_geral_ranking(db)}

@app.get("/ranking/sector", response_model=schemas.RankingResponse) # Retorna do primeiro setor (legado) ou erro
def ranking_sector(db: Session = Depends(get_db), current_user: models.User = Depends(security.get_current_user)):
    if not current_user.sectors:
        return {
            "my_user_id": current_user.user_id, # <--- ADICIONE ISSO
            "ranking": []
        }
    # Retorna o ranking do primeiro setor que o usuário participa
    return {
        "my_user_id": current_user.user_id,
        "ranking": crud.get_sector_ranking(db, current_user.sectors[0].sector_id)
    }

@app.get("/ranking/sector/{sector_id}", response_model=schemas.RankingResponse)
def get_specific_sector_ranking(
    sector_id: int, 
    db: Session = Depends(get_db), 
    current_user: models.User = Depends(security.get_current_user)
):
    """ Retorna o ranking de um setor específico se o usuário fizer parte dele. """
    
    # 1. Verifica se o usuário realmente pertence a esse setor
    # (Isso impede que ele veja ranking de setores que não entrou)
    user_in_sector = False
    for s in current_user.sectors:
        if s.sector_id == sector_id:
            user_in_sector = True
            break
            
    if not user_in_sector:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Você não pertence a este setor.")

    # 2. Busca o ranking
    ranking_data = crud.get_sector_ranking(db, sector_id=sector_id)
    
    return {
        "my_user_id": current_user.user_id,
        "ranking": ranking_data
    }

# --- LIDER ---
@app.get("/lider/pending-users", response_model=List[schemas.UserAdminView])
def pending_users(db: Session = Depends(get_db), current_lider: models.User = Depends(security.get_current_lider)):
    if not current_lider.led_sector: raise HTTPException(status_code=400, detail="Você não lidera nenhum setor.")
    return crud.get_pending_users_by_sector(db, current_lider.led_sector.sector_id)

@app.put("/lider/approve-user/{user_id}")
def approve(user_id: int, db: Session = Depends(get_db), current_lider: models.User = Depends(security.get_current_lider)):
    user = crud.get_user_by_id(db, user_id)
    if not user: raise HTTPException(status_code=404)
    return crud.update_user_status(db, user, models.UserStatus.ACTIVE)

@app.post("/lider/activities")
def create_act(act: schemas.ActivityCreate, db: Session = Depends(get_db), current_lider: models.User = Depends(security.get_current_lider)):
    if not current_lider.led_sector: raise HTTPException(status_code=400, detail="Sem setor.")
    return crud.create_activity(db, act, current_lider)

@app.get("/lider/activities", response_model=List[schemas.Activity])
def get_act(db: Session = Depends(get_db), current_lider: models.User = Depends(security.get_current_lider)):
    if not current_lider.led_sector: return []
    return crud.get_activities_by_sector(db, current_lider.led_sector.sector_id)

@app.get("/lider/users", response_model=List[schemas.UserAdminView])
def get_sec_users(db: Session = Depends(get_db), current_lider: models.User = Depends(security.get_current_lider)):
    if not current_lider.led_sector: return []
    return crud.get_users_by_sector(db, current_lider.led_sector.sector_id)

# --- ADMIN MASTER ---
@app.post("/admin-master/sectors", response_model=schemas.Sector)
def create_sector(name: str = Body(..., embed=True), db: Session = Depends(get_db), admin: models.User = Depends(security.get_current_admin_master)):
    return crud.create_sector(db, name)

@app.get("/admin-master/sectors", response_model=List[schemas.Sector])
def get_sectors(db: Session = Depends(get_db), admin: models.User = Depends(security.get_current_admin_master)):
    return crud.get_all_sectors(db)

@app.get("/admin-master/liders", response_model=List[schemas.UserAdminView])
def get_liders(db: Session = Depends(get_db), admin: models.User = Depends(security.get_current_admin_master)):
    return crud.get_liders(db)

@app.get("/admin-master/users", response_model=List[schemas.UserAdminView])
def get_users(db: Session = Depends(get_db), admin: models.User = Depends(security.get_current_admin_master)):
    return crud.get_all_users(db)

@app.put("/admin-master/users/{user_id}/promote-to-lider")
def promote(user_id: int, db: Session = Depends(get_db), admin: models.User = Depends(security.get_current_admin_master)):
    user = crud.get_user_by_id(db, user_id)
    return crud.update_user_role(db, user, models.UserRole.lider)

@app.put("/admin-master/sectors/{sector_id}/assign-lider")
def assign(sector_id: int, lider_id: int = Body(..., embed=True), db: Session = Depends(get_db), admin: models.User = Depends(security.get_current_admin_master)):
    return crud.assign_lider_to_sector(db, lider_id, sector_id)

# NOVO: Endpoint para baixar Relatório de Auditoria
@app.get("/admin-master/reports/audit")
def download_audit_report(db: Session = Depends(get_db), admin: models.User = Depends(security.get_current_admin_master)):
    """Gera e baixa um arquivo CSV com todos os registros."""
    csv_content = crud.generate_audit_csv(db)
    
    response = StreamingResponse(io.StringIO(csv_content), media_type="text/csv")
    response.headers["Content-Disposition"] = "attachment; filename=auditoria_b10.csv"
    return response