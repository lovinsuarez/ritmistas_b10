# backend/schemas.py
import models
from pydantic import BaseModel, EmailStr, ConfigDict, Field
from datetime import datetime
import uuid
from models import UserRole, UserStatus

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: str | None = None

class UserBase(BaseModel):
    email: EmailStr
    username: str

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=72)

# NOVO: Schema para mostrar pontos por setor
class UserSectorPoints(BaseModel):
    sector_id: int
    sector_name: str
    points: int

class User(UserBase):
    user_id: int
    role: UserRole 
    status: UserStatus
    # Agora retorna uma lista de setores onde o usuário tem pontos
    points_by_sector: list[UserSectorPoints] | None = None
    total_global_points: int | None = None

    model_config = ConfigDict(from_attributes=True) 

class Sector(BaseModel):
    sector_id: int
    name: str
    invite_code: uuid.UUID
    lider_id: int | None
    model_config = ConfigDict(from_attributes=True)

class RedeemCodeRequest(BaseModel):
    code_string: str

class JoinSectorRequest(BaseModel): # NOVO: Para entrar em outro setor
    invite_code: str

class CodeCreateGeneral(BaseModel):
    code_string: str
    points_value: int = 10

class CodeCreateUnique(BaseModel):
    code_string: str
    points_value: int = 10
    assigned_user_id: int

class CheckInRequest(BaseModel):
    activity_id: int

class RankingEntry(BaseModel):
    user_id: int
    username: str
    total_points: int
    model_config = ConfigDict(from_attributes=True)

class RankingResponse(BaseModel):
    ranking: list[RankingEntry]

class UserRegister(UserCreate): 
    invite_code: str 

class SectorInfo(BaseModel):
    name: str
    invite_code: uuid.UUID
    model_config = ConfigDict(from_attributes=True)

class ActivityCreate(BaseModel):
    title: str = Field(..., max_length=150)
    description: str | None = None
    type: models.ActivityType 
    address: str | None = None 
    activity_date: datetime 
    points_value: int = Field(..., gt=0) 

class Activity(ActivityCreate): 
    activity_id: int
    created_by: int
    sector_id: int
    model_config = ConfigDict(from_attributes=True)

class UserAdminView(UserBase): 
    user_id: int
    role: models.UserRole
    status: models.UserStatus
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
    model_config = ConfigDict(from_attributes=True)