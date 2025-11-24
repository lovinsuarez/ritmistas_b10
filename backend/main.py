# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\main.py
from fastapi import FastAPI, Depends, HTTPException, status, Body, Query
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import List, Optional
import io
import crud, models, schemas, security
from database import engine, get_db

models.Base.metadata.create_all(bind=engine)
app = FastAPI(title="Projeto Ritmistas B10 API v3")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

# AUTH
@app.post("/auth/register/admin-master", response_model=schemas.User)
def reg_admin(d: schemas.UserCreate, db: Session = Depends(get_db)):
    if crud.get_user_by_email(db, d.email): raise HTTPException(400, "Email existe.")
    return crud.create_admin_master(db, d)

@app.post("/auth/register/user", response_model=schemas.User, status_code=201)
def reg_user(d: schemas.UserRegister, db: Session = Depends(get_db)):
    if crud.get_user_by_email(db, d.email): raise HTTPException(400, "Email existe.")
    u = crud.create_user_from_invite(db, d)
    if not u: raise HTTPException(400, "Código inválido.")
    return u

@app.post("/auth/token", response_model=schemas.Token)
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    u = crud.get_user_by_email(db, form.username)
    if not u or not security.verify_password(form.password, u.hashed_password): raise HTTPException(401, "Login falhou.")
    if u.status == models.UserStatus.PENDING: raise HTTPException(403, "Conta pendente.")
    token = security.create_access_token(data={"sub": u.email}, expires_delta=timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES))
    return {"access_token": token, "token_type": "bearer"}

# USER
@app.get("/users/me", response_model=schemas.User)
def me(db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    points_data, total_global = crud.get_user_points_breakdown(db, u)
    u.points_by_sector = points_data
    u.total_global_points = total_global
    return u

@app.put("/users/me/profile", response_model=schemas.User)
def update_profile(data: schemas.UserUpdateProfile, db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    return crud.update_user_profile(db, u, data)

@app.post("/user/join-sector")
def join(req: schemas.JoinSectorRequest, db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    return {"detail": crud.join_sector(db, u, req.invite_code)}

@app.post("/user/checkin")
def checkin(req: schemas.CheckInRequest, db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    return {"detail": crud.create_checkin(db, u, req.activity_id)}

@app.post("/user/redeem")
def redeem(req: schemas.RedeemCodeRequest, db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    code = crud.get_code_by_string(db, req.code_string)
    if not code: raise HTTPException(404, "Código inválido.")
    return {"detail": crud.redeem_code(db, u, code)}

# RANKING
@app.get("/ranking/geral", response_model=schemas.RankingResponse)
def rank_geral(month: Optional[int] = Query(None), year: Optional[int] = Query(None), db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    return {"ranking": crud.get_geral_ranking(db, month, year), "my_user_id": u.user_id}

@app.get("/ranking/sector/{sector_id}", response_model=schemas.RankingResponse)
def rank_sector(sector_id: int, month: Optional[int] = Query(None), year: Optional[int] = Query(None), db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    return {"my_user_id": u.user_id, "ranking": crud.get_sector_ranking(db, sector_id, month, year)}

# LIDER
@app.post("/lider/distribute-points")
def distribute(req: schemas.DistributePointsRequest, db: Session = Depends(get_db), lider: models.User = Depends(security.get_current_lider)):
    if not lider.led_sector: raise HTTPException(400, "Sem setor.")
    success, msg = crud.distribute_points_from_budget(db, lider, req.user_id, req.points, req.description)
    if not success: raise HTTPException(400, msg)
    return {"detail": msg}

@app.get("/lider/pending-users", response_model=List[schemas.UserAdminView])
def pending(db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    if not l.led_sector: raise HTTPException(400)
    return crud.get_pending_users_by_sector(db, l.led_sector.sector_id)

@app.put("/lider/approve-user/{user_id}")
def approve(user_id: int, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    u = crud.get_user_by_id(db, user_id)
    return crud.update_user_status(db, u, models.UserStatus.ACTIVE)

@app.delete("/lider/reject-user/{user_id}")
def reject(user_id: int, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    u = crud.get_user_by_id(db, user_id)
    crud.delete_user(db, u)
    return {"ok": True}

@app.post("/lider/activities")
def create_act(act: schemas.ActivityCreate, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    if not l.led_sector: raise HTTPException(400, "Sem setor.")
    return crud.create_activity(db, act, l)

@app.get("/lider/activities", response_model=List[schemas.Activity])
def get_act(db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    if not l.led_sector: return []
    return crud.get_activities_by_sector(db, l.led_sector.sector_id)

@app.get("/lider/users", response_model=List[schemas.UserAdminView])
def get_sec_users(db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    if not l.led_sector: return []
    return crud.get_users_by_sector(db, l.led_sector.sector_id)

@app.delete("/lider/users/{user_id}")
def del_u(user_id: int, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    u = crud.get_user_by_id(db, user_id)
    crud.delete_user(db, u)
    return {"ok": True}

@app.get("/lider/users/{user_id}/dashboard", response_model=schemas.UserDashboard)
def get_user_dash(user_id: int, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    return crud.get_user_dashboard_details(db, user_id, l.led_sector.sector_id if l.led_sector else 0)

@app.post("/lider/codes/general", status_code=status.HTTP_201_CREATED)
def create_gen_code(d: schemas.CodeCreateGeneral, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    if not l.led_sector: raise HTTPException(400)
    return crud.create_general_code(db, d, l)

# ADMIN MASTER
@app.post("/admin-master/budget")
def add_budget(req: schemas.AddBudgetRequest, db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    l = crud.add_budget_to_lider(db, req.lider_id, req.points)
    if not l: raise HTTPException(404)
    return {"detail": "OK"}

@app.post("/admin-master/badges")
def create_badge(b: schemas.BadgeCreate, db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.create_badge(db, b)

@app.post("/admin-master/award-badge")
def award_badge(user_id: int = Body(...), badge_id: int = Body(...), db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return {"detail": crud.award_badge(db, user_id, badge_id)}

@app.get("/admin-master/badges", response_model=List[schemas.Badge])
def get_badges(db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_all_badges(db)

@app.post("/admin-master/sectors", response_model=schemas.Sector)
def create_sec(name: str = Body(..., embed=True), db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.create_sector(db, name)

@app.get("/admin-master/sectors", response_model=List[schemas.Sector])
def get_secs(db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_all_sectors(db)

@app.get("/admin-master/liders", response_model=List[schemas.UserAdminView])
def get_lids(db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_liders(db)

@app.get("/admin-master/users", response_model=List[schemas.UserAdminView])
def get_all_usrs(db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_all_users(db)

@app.put("/admin-master/sectors/{sector_id}/assign-lider")
def assign(sector_id: int, lider_id: int = Body(..., embed=True), db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.assign_lider_to_sector(db, lider_id, sector_id)
    
@app.put("/admin-master/users/{user_id}/promote-to-lider")
def promote(user_id: int, db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    u = crud.get_user_by_id(db, user_id)
    return crud.update_user_role(db, u, models.UserRole.lider)

@app.put("/admin-master/liders/{lider_id}/demote-to-user")
def demote(lider_id: int, db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    u = crud.get_user_by_id(db, lider_id)
    return crud.update_user_role(db, u, models.UserRole.user)

@app.get("/admin-master/sectors/{sector_id}/users", response_model=List[schemas.UserAdminView])
def get_sec_usrs_admin(sector_id: int, db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_users_by_sector(db, sector_id)

@app.get("/admin-master/sectors/{sector_id}/ranking", response_model=schemas.RankingResponse)
def get_sec_rank_admin(sector_id: int, db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return {"my_user_id": a.user_id, "ranking": crud.get_sector_ranking(db, sector_id)}

@app.get("/admin-master/audit/json")
def audit(db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_audit_logs_json(db)

@app.get("/admin-master/reports/audit")
def download_audit(db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    csv_content = crud.generate_audit_csv(db)
    response = StreamingResponse(io.StringIO(csv_content), media_type="text/csv")
    response.headers["Content-Disposition"] = "attachment; filename=auditoria_b10.csv"
    return response