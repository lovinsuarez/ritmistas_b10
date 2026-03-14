from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import crud, models, schemas, security
from database import get_db

router = APIRouter(prefix="/activities", tags=["activities"])

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
