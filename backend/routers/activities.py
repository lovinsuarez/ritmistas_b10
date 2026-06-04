from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import crud, models, schemas, security
from database import get_db

router = APIRouter(prefix="/activities", tags=["activities"])

# Alias router with /lider prefix — matches frontend API calls
lider_router = APIRouter(prefix="/lider", tags=["lider"])

@router.post("/", status_code=status.HTTP_201_CREATED)
def create_act(act: schemas.ActivityCreate, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    if not l.led_sector:
        raise HTTPException(400, "Sem setor.")
    return crud.create_activity(db, act, l)

@router.get("/", response_model=List[schemas.Activity])
def get_act(db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    if not l.led_sector:
        return []
    return crud.get_activities_by_sector(db, l.led_sector.sector_id)

@router.post("/distribute-points")
def distribute(req: schemas.DistributePointsRequest, db: Session = Depends(get_db), lider: models.User = Depends(security.get_current_lider)):
    if not lider.led_sector:
        raise HTTPException(400, "Sem setor.")
    success, msg = crud.distribute_points_from_budget(db, lider, req.user_id, req.points, req.description)
    if not success:
        raise HTTPException(400, msg)
    return {"detail": msg}

# ── /lider/* aliases (frontend uses this prefix) ──────────────────────────────

@lider_router.post("/activities", status_code=status.HTTP_201_CREATED)
def lider_create_act(act: schemas.ActivityCreate, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    if not l.led_sector:
        raise HTTPException(400, "Sem setor.")
    return crud.create_activity(db, act, l)

@lider_router.get("/activities", response_model=List[schemas.Activity])
def lider_get_act(db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    if not l.led_sector:
        return []
    return crud.get_activities_by_sector(db, l.led_sector.sector_id)

@lider_router.post("/distribute-points")
def lider_distribute(req: schemas.DistributePointsRequest, db: Session = Depends(get_db), lider: models.User = Depends(security.get_current_lider)):
    if not lider.led_sector:
        raise HTTPException(400, "Sem setor.")
    success, msg = crud.distribute_points_from_budget(db, lider, req.user_id, req.points, req.description)
    if not success:
        raise HTTPException(400, msg)
    return {"detail": msg}

@lider_router.get("/users", response_model=List[schemas.UserAdminView])
def lider_get_users(db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    if not l.led_sector:
        return []
    return crud.get_users_by_sector(db, l.led_sector.sector_id)

@lider_router.get("/pending-users", response_model=List[schemas.UserAdminView])
def lider_pending_users(db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    if not l.led_sector:
        return []
    return crud.get_pending_users_by_sector(db, l.led_sector.sector_id)

@lider_router.put("/approve-user/{user_id}")
def lider_approve_user(user_id: int, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    u = crud.get_user_by_id(db, user_id)
    if not u:
        raise HTTPException(404, "Usuário não encontrado.")
    return crud.update_user_status(db, u, models.UserStatus.ACTIVE)

@lider_router.delete("/reject-user/{user_id}")
def lider_reject_user(user_id: int, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    u = crud.get_user_by_id(db, user_id)
    if not u:
        raise HTTPException(404, "Usuário não encontrado.")
    return crud.update_user_status(db, u, models.UserStatus.REJECTED)

@lider_router.delete("/users/{user_id}")
def lider_delete_user(user_id: int, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    u = crud.get_user_by_id(db, user_id)
    if not u:
        raise HTTPException(404, "Usuário não encontrado.")
    db.delete(u)
    db.commit()
    return {"detail": "Usuário removido."}

@lider_router.get("/users/{user_id}/dashboard", response_model=schemas.UserDashboard)
def lider_user_dashboard(user_id: int, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    return crud.get_user_dashboard(db, user_id)

@lider_router.post("/codes/general", status_code=status.HTTP_201_CREATED)
def lider_create_general_code(d: schemas.CodeCreateGeneral, db: Session = Depends(get_db), l: models.User = Depends(security.get_current_lider)):
    d.is_general = False  # Lider codes are sector-scoped
    return crud.create_general_code(db, d, l)
