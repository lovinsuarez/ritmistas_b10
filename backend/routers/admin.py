from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session
from typing import List
import crud, models, schemas, security
from database import get_db

router = APIRouter(prefix="/admin", tags=["admin"])

@router.get("/users", response_model=List[schemas.UserAdminView])
def get_all_usrs(db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_all_users(db)

@router.get("/pending-global", response_model=List[schemas.UserAdminView])
def get_pending_global(db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_pending_global_users(db)

@router.put("/approve-global/{user_id}")
def approve_global(user_id: int, db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    u = crud.get_user_by_id(db, user_id)
    return crud.update_user_status(db, u, models.UserStatus.ACTIVE)

@router.post("/budget")
def add_budget(req: schemas.AddBudgetRequest, db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    l = crud.add_budget_to_lider(db, req.lider_id, req.points)
    if not l:
        raise HTTPException(404)
    return {"detail": "OK"}

@router.get("/audit/json")
def audit(db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_audit_logs_json(db)

@router.post("/codes/general", status_code=status.HTTP_201_CREATED)
def create_admin_general_code(d: schemas.CodeCreateGeneral, db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    d.is_general = True
    return crud.create_general_code(db, d, a)

@router.get("/codes/general", response_model=List[schemas.CodeDetail])
def get_admin_codes(db: Session = Depends(get_db), a: models.User = Depends(security.get_current_admin_master)):
    return crud.get_general_codes(db)
