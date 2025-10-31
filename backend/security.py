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

# --- Configuração de Autenticação ---

# 1. Configuração de Hashing de Senha (usando bcrypt)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# 2. Configuração do JWT
# IMPORTANTE: Cole sua chave secreta gerada no terminal aqui!
SECRET_KEY = "fc6151968f29a237ba0aec3e1f1ecb0c1627511dde8c853ac91636325e01325f"
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
):
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