from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import crud, models, schemas, security
from database import get_db

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/me", response_model=schemas.UserResponse)
def me(db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    points_data, total_global = crud.get_user_points_breakdown(db, u)
    u.points_by_sector = points_data
    u.total_global_points = total_global
    if u.led_sector:
        u.invite_code = u.led_sector.invite_code
    else:
        u.invite_code = None
    return u

@router.put("/me/profile", response_model=schemas.User)
def update_profile(data: schemas.UserUpdateProfile, db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    updated_user = crud.update_user_profile(db, u, data)
    
    # Ecosystem Event Emission Placeholder
    # In a real integration, this would emit to BullMQ, NATS, or a Webhook
    print(f"[ECOSYSTEM EVENT] user.profile_updated: user_id={u.external_id}, full_name={u.username}")
    
    return updated_user

@router.post("/join-sector")
def join(req: schemas.JoinSectorRequest, db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    return {"detail": crud.join_sector(db, u, req.invite_code)}

@router.post("/checkin")
def checkin(req: schemas.CheckInRequest, db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    return {"detail": crud.create_checkin(db, u, req.activity_code)}

@router.post("/redeem")
def redeem(req: schemas.RedeemCodeRequest, db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    code = crud.get_code_by_string(db, req.code_string)
    if not code:
        raise HTTPException(404, "Código inválido.")
    return {"detail": crud.redeem_code(db, u, code)}
