from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import crud, models, schemas, security
from database import get_db

router = APIRouter(prefix="/ranking", tags=["ranking"])

@router.get("/geral", response_model=schemas.RankingResponse)
def rank_geral(month: Optional[int] = Query(None), year: Optional[int] = Query(None), db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    return {"ranking": crud.get_geral_ranking(db, month, year), "my_user_id": u.user_id}

@router.get("/sector/{sector_id}", response_model=schemas.RankingResponse)
def rank_sector(sector_id: int, month: Optional[int] = Query(None), year: Optional[int] = Query(None), db: Session = Depends(get_db), u: models.User = Depends(security.get_current_user)):
    return {"my_user_id": u.user_id, "ranking": crud.get_sector_ranking(db, sector_id, month, year)}
