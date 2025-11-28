# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\security.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
import crud, database
from datetime import datetime, timedelta, timezone
from passlib.context import CryptContext
from jose import JWTError, jwt
from pydantic import BaseModel
import schemas # Importa os schemas que criamos

# NOVO: Importar os modelos User e UserRole
from models import User, UserRole

# --- Configuração de Autenticação ---

# 1. Configuração de Hashing de Senha (usando bcrypt)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# 2. Configuração do JWT
import os

# SECRET_KEY should come from environment in production. A default is provided
# for local development but you MUST set a strong SECRET_KEY in Render.
SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-change-me")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 dias
# Esta é a URL que o FastAPI usará para saber "como" o usuário faz login
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")

# --- Funções de Segurança ---

def verify_password(plain_password, hashed_password):
    """Verifica se a senha pura bate com a senha criptografada."""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str): # Adiciona o 'str' para clareza
    """Gera o hash de uma senha pura."""

    # O Bcrypt tem um limite de 72 caracteres.
    # Vamos truncar (cortar) a senha antes de hashear.
    if len(password) > 72:
        password = password[:72]

    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: timedelta | None = None):
    """Cria um novo token JWT."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_token(token: str) -> schemas.TokenData | None:
    """Decodifica um token, validando-o."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            return None
        return schemas.TokenData(email=email)
    except JWTError:
        return None

def get_current_user(
    token: str = Depends(oauth2_scheme), 
    db: Session = Depends(database.get_db)
) -> User: # ALTERADO: Adicionado o tipo de retorno '-> User' para clareza
    """
    Dependência para obter o usuário logado atualmente.
    Decodifica o token, busca o usuário no banco e o retorna.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Não foi possível validar as credenciais",
        headers={"WWW-Authenticate": "Bearer"},
    )

    token_data = decode_token(token)
    if token_data is None or token_data.email is None:
        raise credentials_exception

    user = crud.get_user_by_email(db, email=token_data.email)
    if user is None:
        raise credentials_exception

    return user

# --- NOVAS DEPENDÊNCIAS DE AUTORIZAÇÃO ---

def get_current_lider(current_user: User = Depends(get_current_user)) -> User:
    """
    Dependência que verifica se o usuário é LÍDER ou ADMIN MASTER.
    (Líder = "1", Admin = "0")
    """
    if current_user.role not in [UserRole.lider, UserRole.admin]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado: Requer permissão de Líder ou Admin Master",
        )
    return current_user

def get_current_admin_master(current_user: User = Depends(get_current_user)) -> User:
    """
    Dependência que verifica se o usuário é ADMIN MASTER.
    (Admin = "0")
    """
    if current_user.role != UserRole.admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado: Requer permissão de Admin Master",
        )
    return current_user