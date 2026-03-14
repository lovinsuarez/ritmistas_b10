from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from typing import List
import crud, models, schemas, security
from database import get_db

router = APIRouter(prefix="/sectors", tags=["sectors"])

@router.get("/", response_model=List[schemas.Sector])
def get_secs(db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_all_sectors(db)

@router.post("/", response_model=schemas.Sector)
def create_sec(name: str = Body(..., embed=True), db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.create_sector(db, name)

@router.put("/{sector_id}/assign-lider")
def assign(sector_id: int, lider_id: int = Body(..., embed=True), db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.assign_lider_to_sector(db, lider_id, sector_id)

@router.get("/{sector_id}/users", response_model=List[schemas.UserAdminView])
def get_sec_usrs_admin(sector_id: int, db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_users_by_sector(db, sector_id)

@router.get("/{sector_id}/ranking", response_model=schemas.RankingResponse)
def get_sec_rank_admin(sector_id: int, db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return {"my_user_id": a.user_id, "ranking": crud.get_sector_ranking(db, sector_id)}
