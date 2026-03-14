import models
from pydantic import BaseModel, EmailStr, ConfigDict, Field, model_validator
from datetime import datetime, date
import uuid
from models import UserRole, UserStatus

class BaseConfig(BaseModel):
    model_config = ConfigDict(from_attributes=True, use_enum_values=True)

# ... (Token schemas) ...

# User
class UserBase(BaseConfig):
    email: EmailStr
    username: str # Nickname
    first_name: str | None = None
    last_name: str | None = None
    nickname: str | None = None # Deprecated: use username

class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=72)

class UserRegister(UserCreate): 
    invite_code: str 

class UserUpdateProfile(BaseConfig):
    username: str | None = None # Nickname update
    first_name: str | None = None
    last_name: str | None = None
    nickname: str | None = None # Deprecated
    birth_date: date | None = None
    profile_pic: str | None = None

class UserSectorPoints(BaseConfig):
    sector_id: int
    sector_name: str
    points: int

class User(UserBase):
    user_id_int: int = Field(alias="user_id", validation_alias="user_id", serialization_alias="user_id") # Internal DB ID
    user_id: uuid.UUID = Field(alias="external_id", validation_alias="external_id", serialization_alias="user_id") # Ecosystem UUID
    role: UserRole 
    status: UserStatus
    full_name: str | None = None # Computed
    photo_url: str | None = Field(None, alias="profile_pic", validation_alias="profile_pic", serialization_alias="photo_url")
    birth_date: date | None = None
    points_budget: int = 0
    points_by_sector: list[UserSectorPoints] | None = None
    total_global_points: int | None = None
    badges: list[UserBadge] = []
    last_recovery_code: str | None = None
    
    @model_validator(mode='after')
    def compute_full_name(self) -> 'User':
        if self.first_name and self.last_name:
            self.full_name = f"{self.first_name} {self.last_name}"
        elif self.first_name:
            self.full_name = self.first_name
        else:
            self.full_name = self.username # Fallback for old users or missing names
        return self

    model_config = ConfigDict(populate_by_name=True)

# Outros
class Sector(BaseConfig):
    sector_id: int
    name: str
    invite_code: uuid.UUID
    lider_id: int | None

class RedeemCodeRequest(BaseConfig): code_string: str
class JoinSectorRequest(BaseConfig): invite_code: str
class DistributePointsRequest(BaseConfig):
    user_id: int
    points: int
    description: str
class AddBudgetRequest(BaseConfig):
    lider_id: int
    points: int

# Pontos Gerais (Com Título)
class CodeCreateGeneral(BaseConfig):
    points_value: int = 10
    is_general: bool = False
    title: str | None = None
    description: str | None = None
    event_date: datetime | None = None

class CodeCreateUnique(BaseConfig):
    code_string: str
    points_value: int = 10
    assigned_user_id: int
    is_general: bool = False

class CheckInRequest(BaseConfig): activity_code: str 

class RankingEntry(BaseConfig):
    user_id: int
    username: str
    nickname: str | None = None
    profile_pic: str | None = None
    total_points: int
class RankingResponse(BaseConfig):
    my_user_id: int
    ranking: list[RankingEntry]

class SectorInfo(BaseConfig):
    name: str
    invite_code: uuid.UUID

class ActivityCreate(BaseConfig):
    title: str = Field(..., max_length=150)
    description: str | None = None
    type: models.ActivityType 
    address: str | None = None 
    activity_date: datetime 
    points_value: int = Field(..., gt=0) 
    is_general: bool = False
class Activity(ActivityCreate): 
    activity_id: int
    created_by: int
    sector_id: int | None
    checkin_code: str | None = None

class UserAdminView(UserBase): 
    user_id: int
    role: UserRole
    status: UserStatus

class CheckInDetail(BaseConfig):
    title: str
    points: int
    date: datetime
    is_general: bool = False

# Lista de Códigos (Nomes Corrigidos)
class CodeDetail(BaseConfig):
    code_string: str
    points_value: int
    created_at: datetime
    is_general: bool = False
    title: str | None = None
    description: str | None = None
    event_date: datetime | None = None

class UserDashboard(BaseConfig):
    user_id: int
    username: str
    total_points: int
    checkins: list[CheckInDetail]
    redeemed_codes: list[CodeDetail]
class UserResponse(User): 
    invite_code: uuid.UUID | None = None 
class AuditLogItem(BaseConfig):
    timestamp: datetime
    type: str 
    user_name: str
    lider_name: str
    sector_name: str
    description: str
    points: int
    is_general: bool

class GoogleLoginRequest(BaseConfig):
    email: EmailStr
    username: str # Nickname
    first_name: str | None = None
    last_name: str | None = None
    google_id: str
    invite_code: str | None = None
    

class RecoverPasswordRequest(BaseConfig):
    email: EmailStr
    code: str
    new_password: str = Field(..., min_length=8, max_length=72)
    