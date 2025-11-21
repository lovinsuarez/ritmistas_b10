# C:\Users\jeatk\OneDrive\Documents\GitHub\ritimistas_b10\backend\schemas.py
import models
from pydantic import BaseModel, EmailStr, ConfigDict, Field
from datetime import datetime
import uuid
from models import UserRole, UserStatus # ALTERADO: Importa também o UserStatus

# --- Schemas para TOKEN (Autenticação) ---
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: str | None = None

# --- Schemas base para USUÁRIO ---
class UserBase(BaseModel):
    email: EmailStr
    username: str

# Schema para Criar um Usuário (recebe senha)
class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=72)

# Schema para Criar um Admin (recebe senha e nome do setor)
class AdminCreate(UserCreate):
    sector_name: str

# Schema para exibir um Usuário (nunca mostrar a senha)
class User(UserBase):
    user_id: int
    role: UserRole 
    sector_id: int | None 
    status: models.UserStatus # NOVO: Adiciona o status

    model_config = ConfigDict(from_attributes=True) 

# --- Schemas para SETOR ---
class Sector(BaseModel):
    sector_id: int
    name: str
    invite_code: uuid.UUID
    lider_id: int | None

    model_config = ConfigDict(from_attributes=True)

class RedeemCodeRequest(BaseModel):
    code_string: str

class CodeCreateBase(BaseModel):
    code_string: str
    points_value: int = 10

class CodeCreateGeneral(CodeCreateBase):
    pass

class CodeCreateUnique(CodeCreateBase):
    assigned_user_id: int

class CheckInRequest(BaseModel):
    activity_id: int

# --- Schemas para Ranking ---
class RankingEntry(BaseModel):
    user_id: int
    username: str
    total_points: int

    model_config = ConfigDict(from_attributes=True)

class RankingResponse(BaseModel):
    my_user_id: int
    ranking: list[RankingEntry]

# --- Schemas para Registro de Usuário (via convite) ---
class UserRegister(UserCreate): 
    invite_code: str 

class SectorInfo(BaseModel):
    name: str
    invite_code: uuid.UUID

    model_config = ConfigDict(from_attributes=True)

# --- Schemas para Atividades ---
class ActivityCreate(BaseModel):
    title: str = Field(..., max_length=150)
    description: str | None = None
    type: models.ActivityType 
    address: str | None = None 
    activity_date: datetime 
    points_value: int = Field(..., gt=0) 

# Schema para exibir uma atividade (inclui o ID)
class Activity(ActivityCreate): 
    activity_id: int
    created_by: int
    sector_id: int

    model_config = ConfigDict(from_attributes=True)

# --- Schemas para Admin (Gerenciamento de Usuário) ---
class UserAdminView(UserBase): 
    user_id: int
    role: models.UserRole
    status: models.UserStatus # NOVO: Adiciona o status

    model_config = ConfigDict(from_attributes=True)

class CheckInDetail(BaseModel):
    title: str
    points: int
    date: datetime

    model_config = ConfigDict(from_attributes=True)

class CodeDetail(BaseModel):
    code_string: str
    points: int
    date: datetime

    model_config = ConfigDict(from_attributes=True)

class UserDashboard(BaseModel):
    user_id: int
    username: str
    total_points: int
    checkins: list[CheckInDetail]
    redeemed_codes: list[CodeDetail]

class UserResponse(User): 
    invite_code: uuid.UUID | None = None 
    status: models.UserStatus # NOVO: Adiciona o status

    model_config = ConfigDict(from_attributes=True)