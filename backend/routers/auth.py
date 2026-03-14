from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import List
import crud, models, schemas, security
from database import get_db

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/token", response_model=schemas.Token)
def login(form: schemas.TokenData = Depends(), db: Session = Depends(get_db)):
    # Note: Transitioning to Launchpad auth. Internal login kept for compatibility.
    u = crud.get_user_by_email(db, form.email)
    if not u or not security.verify_password(form.password, u.hashed_password):
        raise HTTPException(401, "Login falhou.")
    if u.status == models.UserStatus.PENDING:
        raise HTTPException(403, "Conta pendente de aprovação do Admin Master.")
    
    token = security.create_access_token(
        data={"user_uuid": u.external_id, "role": u.role}, 
        expires_delta=timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return {"access_token": token, "token_type": "bearer"}

@router.post("/send-recovery-password-email")
def send_recovery_email_endpoint(
    to_address: str = Query(...),
    db: Session = Depends(get_db),
):
    from mailer import send_recovery_email_to_address
    try:
        send_recovery_email_to_address(db, to_address)
        return {"detail": "OK"}
    except ValueError as e:
        if str(e) == "USER_NOT_FOUND":
            raise HTTPException(status_code=404, detail="Usuário não encontrado.")
        raise

@router.post("/recover-password")
def recover_password_endpoint(data: schemas.RecoverPasswordRequest, db: Session = Depends(get_db)):
    user = crud.get_user_by_email(db, data.email)
    if not user:
        raise HTTPException(404, "Usuário não encontrado.")
    if not crud.check_recovery_code(db, user, data.code):
        raise HTTPException(400, "Código inválido.")

    crud.update_user_password(db, user, data.new_password)
    crud.clear_recovery_code(db, user)
    return {"detail": "Senha atualizada com sucesso."}
