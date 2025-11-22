# backend/schemas.py
import models
from pydantic import BaseModel, EmailStr, ConfigDict, Field
from datetime import datetime, date
import uuid
from models import UserRole, UserStatus

# --- Schemas de Insígnias ---
class BadgeBase(BaseModel):
    name: str
    description: str | None = None
    icon_url: str | None = None

class BadgeCreate(BadgeBase):
    pass

class Badge(BadgeBase):
    badge_id: int
    model_config = ConfigDict(from_attributes=True)

class UserBadge(BaseModel):
    badge: Badge
    awarded_at: datetime
    model_config = ConfigDict(from_attributes=True)

# --- Schemas de Usuário ---
class Token(BaseModel):
    access_token: str
    token_type: str

class UserBase(BaseModel):
    email: EmailStr
    username: str
    nickname: str | None = None # NOVO

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=72)

class UserUpdateProfile(BaseModel): # NOVO: Para editar perfil
    nickname: str | None = None
    birth_date: date | None = None
    profile_pic: str | None = None # URL ou Base64

class UserSectorPoints(BaseModel):
    sector_id: int
    sector_name: str
    points: int

class User(UserBase):
    user_id: int
    role: UserRole 
    status: UserStatus
    birth_date: date | None = None # NOVO
    profile_pic: str | None = None # NOVO
    points_budget: int = 0 # NOVO (Para líderes)
    
    # Dados calculados
    points_by_sector: list[UserSectorPoints] | None = None
    total_global_points: int | None = None
    badges: list[UserBadge] = [] # NOVO

    model_config = ConfigDict(from_attributes=True) 

# --- Outros Schemas ---
class Sector(BaseModel):
    sector_id: int
    name: str
    invite_code: uuid.UUID
    lider_id: int | None
    model_config = ConfigDict(from_attributes=True)

class RedeemCodeRequest(BaseModel):
    code_string: str

class JoinSectorRequest(BaseModel):
    invite_code: str

# NOVO: Para o líder distribuir pontos do orçamento
class DistributePointsRequest(BaseModel):
    user_id: int
    points: int
    description: str # Ex: "Bom desempenho"

# NOVO: Para o Admin dar orçamento ao líder
class AddBudgetRequest(BaseModel):
    lider_id: int
    points: int

class CodeCreateGeneral(BaseModel):
    code_string: str
    points_value: int = 10
    is_general: bool = False # NOVO

class CodeCreateUnique(BaseModel):
    code_string: str
    points_value: int = 10
    assigned_user_id: int
    is_general: bool = False # NOVO

class CheckInRequest(BaseModel):
    activity_id: int

class RankingEntry(BaseModel):
    user_id: int
    username: str
    nickname: str | None = None # NOVO
    profile_pic: str | None = None # NOVO
    total_points: int
    model_config = ConfigDict(from_attributes=True)

class RankingResponse(BaseModel):
    my_user_id: int
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
    is_general: bool = False # NOVO

class Activity(ActivityCreate): 
    activity_id: int
    created_by: int
    sector_id: int | None
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
    is_general: bool = False
    model_config = ConfigDict(from_attributes=True)

class CodeDetail(BaseModel):
    code_string: str
    points: int
    date: datetime
    is_general: bool = False
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

class AuditLogItem(BaseModel):
    timestamp: datetime
    type: str 
    user_name: str
    lider_name: str
    sector_name: str
    description: str
    points: int
    is_general: bool # NOVO